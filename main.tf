data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# 0. UNIQUENESS HELPER
# S3 bucket names are globally unique across ALL AWS accounts, so a static
# name ("medallion-lake-smallbiz") will eventually collide with someone
# else's bucket. This appends a short random suffix instead.
# ------------------------------------------------------------------------------
resource "random_id" "suffix" {
  byte_length = 4
}

# ------------------------------------------------------------------------------
# 1. NETWORKING (VPC, Gateway Endpoint, flow logs, locked-down default SG)
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "medallion-vpc" }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = { Name = "medallion-private-subnet" }
}

# Gateway Endpoint keeps S3 traffic inside AWS (no NAT Gateway needed = $0/mo)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = { Name = "s3-vpc-endpoint" }
}

# Every VPC gets an unmanaged default security group. Left alone, it
# usually has an "allow all traffic from self" rule. Managing it explicitly
# with no ingress/egress blocks strips that down to deny-everything.
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "medallion-default-sg-locked-down" }
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "medallion-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = { Name = "medallion-vpc-flow-logs-role" }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "medallion-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/medallion-flow-logs"
  retention_in_days = 30

  tags = { Name = "medallion-vpc-flow-logs" }
}

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  traffic_type          = "ALL"
  log_destination_type  = "cloud-watch-logs"
  log_destination       = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn          = aws_iam_role.vpc_flow_logs.arn

  tags = { Name = "medallion-vpc-flow-log" }
}

# ------------------------------------------------------------------------------
# 2. SECURITY (KMS Customer-Managed Key with explicit policy)
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "kms_key_policy" {
  # Root account must retain full admin rights over the key, or the key can
  # become unmanageable (this is the AWS-recommended baseline statement).
  statement {
    sid    = "EnableRootAccountFullAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Scoped to just the AWS services that actually need to encrypt/decrypt
  # with this key — S3 (data lake + access logs), Glue, and Athena.
  statement {
    sid    = "AllowServiceUsage"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "s3.amazonaws.com",
        "logging.s3.amazonaws.com",
        "glue.amazonaws.com",
        "athena.amazonaws.com",
      ]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_key" "data_lake_key" {
  description             = "KMS key for Medallion data lake encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json

  tags = { Name = "medallion-kms-key" }
}

resource "aws_kms_alias" "data_lake_key_alias" {
  name          = "alias/medallion-data-lake"
  target_key_id = aws_kms_key.data_lake_key.key_id
}

# ------------------------------------------------------------------------------
# 3. ACCESS LOG BUCKET
# Dedicated bucket that receives S3 server access logs from the data lake
# bucket. It logs to itself (AWS explicitly supports this) so it doesn't
# need a second bucket just to satisfy its own logging requirement.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "access_logs" {
  bucket        = "medallion-lake-logs-${var.environment_name}-${random_id.suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data_lake_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "access_logs" {
  bucket        = aws_s3_bucket.access_logs.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "self-access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}

    expiration {
      days = 180
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Grants the S3 log-delivery service permission to write into this bucket.
resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "S3ServerAccessLogsPolicy"
      Effect    = "Allow"
      Principal = { Service = "logging.s3.amazonaws.com" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.access_logs.arn}/*"
      Condition = {
        ArnLike = {
          "aws:SourceArn" = [
            aws_s3_bucket.medallion_lake.arn,
            aws_s3_bucket.access_logs.arn,
          ]
        }
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }]
  })
}

# ------------------------------------------------------------------------------
# 4. MEDALLION S3 DATA LAKE (Bronze / Silver / Gold)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "medallion_lake" {
  bucket = "medallion-lake-${var.environment_name}-${random_id.suffix.hex}"

  # NOTE: force_destroy = true means `terraform destroy` deletes ALL objects
  # in this bucket, including any data teams have loaded. That's what makes
  # the automatic rollback-on-failure requirement work, but it also means
  # this bucket is NOT a safe place for data you can't afford to lose to a
  # failed pipeline run. Flip this to false once you trust the pipeline.
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "medallion_lake" {
  bucket = aws_s3_bucket.medallion_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "medallion_lake" {
  bucket                  = aws_s3_bucket.medallion_lake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "medallion_lake" {
  bucket = aws_s3_bucket.medallion_lake.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.data_lake_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "medallion_lake" {
  bucket        = aws_s3_bucket.medallion_lake.id
  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "medallion-lake-access-logs/"
}

resource "aws_s3_bucket_lifecycle_configuration" "medallion_lake" {
  bucket = aws_s3_bucket.medallion_lake.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_object" "bronze_folder" {
  bucket = aws_s3_bucket.medallion_lake.id
  key    = "bronze/"
}

resource "aws_s3_object" "silver_folder" {
  bucket = aws_s3_bucket.medallion_lake.id
  key    = "silver/"
}

resource "aws_s3_object" "gold_folder" {
  bucket = aws_s3_bucket.medallion_lake.id
  key    = "gold/"
}

# ------------------------------------------------------------------------------
# 5. METADATA CATALOG & QUERY ENGINE
# ------------------------------------------------------------------------------
resource "aws_glue_catalog_database" "medallion_catalog" {
  name = "medallion_catalog_db"
}

resource "aws_athena_workgroup" "analytics" {
  name = "medallion_analytics_workgroup"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.medallion_lake.bucket}/gold/athena-results/"

      encryption_configuration {
        encryption_option = "SSE_KMS"
        kms_key_arn       = aws_kms_key.data_lake_key.arn
      }
    }
  }
}

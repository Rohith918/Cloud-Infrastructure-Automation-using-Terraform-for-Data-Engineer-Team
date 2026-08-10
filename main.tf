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
# 1. NETWORKING (VPC & Gateway Endpoint)
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

# ------------------------------------------------------------------------------
# 2. SECURITY (KMS Customer-Managed Key)
# ------------------------------------------------------------------------------
resource "aws_kms_key" "data_lake_key" {
  description             = "KMS key for Medallion data lake encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = { Name = "medallion-kms-key" }
}

resource "aws_kms_alias" "data_lake_key_alias" {
  name          = "alias/medallion-data-lake"
  target_key_id = aws_kms_key.data_lake_key.key_id
}

# ------------------------------------------------------------------------------
# 3. MEDALLION S3 DATA LAKE (Bronze / Silver / Gold)
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
# 4. METADATA CATALOG & QUERY ENGINE
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

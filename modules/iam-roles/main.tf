# One role per function - never a single shared "data-team-role". Each
# role's policy is scoped to only the S3 tier ARNs it actually needs.

resource "aws_iam_role" "emr" {
  name = "${var.name_prefix}-emr-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "elasticmapreduce.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "emr" {
  name = "${var.name_prefix}-emr-policy"
  role = aws_iam_role.emr.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadRawBucket"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [var.raw_bucket_arn, "${var.raw_bucket_arn}/*"]
      },
      {
        Sid      = "WriteCuratedAndAnalytics"
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject"]
        Resource = [
          var.curated_bucket_arn, "${var.curated_bucket_arn}/*",
          var.analytics_bucket_arn, "${var.analytics_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "emr" {
  name = "${var.name_prefix}-emr-instance-profile"
  role = aws_iam_role.emr.name
}

resource "aws_iam_role" "mwaa" {
  name = "${var.name_prefix}-mwaa-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = ["airflow.amazonaws.com", "airflow-env.amazonaws.com"]
      }
      Action = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "mwaa" {
  name = "${var.name_prefix}-mwaa-policy"
  role = aws_iam_role.mwaa.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DagBucketAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket", "s3:GetBucketLocation"]
        Resource = [var.dag_bucket_arn, "${var.dag_bucket_arn}/*"]
      },
      {
        Sid      = "TriggerEmrJobs"
        Effect   = "Allow"
        Action   = ["elasticmapreduce:AddJobFlowSteps", "elasticmapreduce:DescribeStep", "elasticmapreduce:DescribeCluster"]
        Resource = "*"
      },
      {
        Sid      = "CloudWatchLogs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:CreateLogGroup", "logs:PutLogEvents", "logs:GetLogEvents"]
        Resource = "arn:aws:logs:*:*:log-group:airflow-${var.name_prefix}-*"
      }
    ]
  })
}

resource "aws_iam_role" "glue" {
  name = "${var.name_prefix}-glue-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "glue" {
  name = "${var.name_prefix}-glue-policy"
  role = aws_iam_role.glue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CrawlAllTiers"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          var.raw_bucket_arn, "${var.raw_bucket_arn}/*",
          var.curated_bucket_arn, "${var.curated_bucket_arn}/*",
          var.analytics_bucket_arn, "${var.analytics_bucket_arn}/*"
        ]
      },
      {
        Sid      = "CatalogWrite"
        Effect   = "Allow"
        Action   = ["glue:*"]
        Resource = "*"
      }
    ]
  })
}

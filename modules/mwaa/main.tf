resource "aws_s3_bucket" "dags" {
  bucket = "${var.environment_name}-dags"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "dags" {
  bucket = aws_s3_bucket.dags.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "dags" {
  bucket                  = aws_s3_bucket.dags.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_security_group" "mwaa" {
  name_prefix = "${var.environment_name}-mwaa-"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_mwaa_environment" "this" {
  name              = var.environment_name
  airflow_version   = var.airflow_version
  environment_class = var.environment_class
  execution_role_arn = var.execution_role_arn

  source_bucket_arn = aws_s3_bucket.dags.arn
  dag_s3_path       = "dags/"

  network_configuration {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.mwaa.id]
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    task_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  tags = var.tags
}

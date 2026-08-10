output "vpc_id" {
  value = aws_vpc.main.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.medallion_lake.bucket
}

output "kms_key_arn" {
  value = aws_kms_key.data_lake_key.arn
}

output "glue_catalog_database" {
  value = aws_glue_catalog_database.medallion_catalog.name
}

output "athena_workgroup" {
  value = aws_athena_workgroup.analytics.name
}

output "access_logs_bucket_name" {
  value = aws_s3_bucket.access_logs.bucket
}

output "vpc_flow_log_group" {
  value = aws_cloudwatch_log_group.vpc_flow_logs.name
}

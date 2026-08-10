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

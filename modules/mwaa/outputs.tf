output "mwaa_arn" {
  value = aws_mwaa_environment.this.arn
}

output "webserver_url" {
  value = aws_mwaa_environment.this.webserver_url
}

output "dag_bucket_arn" {
  value = aws_s3_bucket.dags.arn
}

output "dag_bucket_name" {
  value = aws_s3_bucket.dags.id
}

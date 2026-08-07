output "vpc_id" {
  value = module.networking.vpc_id
}

output "data_lake_buckets" {
  value = module.data_lake.bucket_names
}
#One More Commit
output "mwaa_webserver_url" {
  value = module.mwaa.webserver_url
}

output "redshift_endpoint" {
  value = module.redshift.workgroup_endpoint
}

output "kinesis_stream_name" {
  value = module.streaming.stream_name
}

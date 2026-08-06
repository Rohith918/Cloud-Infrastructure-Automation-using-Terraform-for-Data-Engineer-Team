output "workgroup_endpoint" {
  value = aws_redshiftserverless_workgroup.this.endpoint
}

output "namespace_id" {
  value = aws_redshiftserverless_namespace.this.namespace_id
}

output "cluster_id" {
  value = aws_emr_cluster.this.id
}

output "master_public_dns" {
  value = aws_emr_cluster.this.master_public_dns
}

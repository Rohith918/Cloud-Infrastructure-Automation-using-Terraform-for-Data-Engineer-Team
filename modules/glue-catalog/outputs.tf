output "database_names" {
  value = { for k, v in aws_glue_catalog_database.tier : k => v.name }
}

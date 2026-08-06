# Minimal Lake Formation setup - registers the data lake admin and grants
# the Glue role permission on each catalog database. Column/row-level PII
# permissions get added here as the DE team defines classification needs.

resource "aws_lakeformation_data_lake_settings" "this" {
  admins = [var.admin_role_arn]
}

resource "aws_lakeformation_permissions" "glue_database_access" {
  for_each    = var.database_names
  principal   = var.glue_role_arn
  permissions = ["ALL"]

  database {
    name = each.value
  }

  depends_on = [aws_lakeformation_data_lake_settings.this]
}

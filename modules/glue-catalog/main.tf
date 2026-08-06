resource "aws_glue_catalog_database" "tier" {
  for_each = toset(["raw", "curated", "analytics"])
  name     = "${var.name_prefix}_${each.key}"
}

# Crawler is provisioned (schedule, target, role) - the DE team owns what
# schemas actually show up; we just make discovery automatic.
resource "aws_glue_crawler" "raw" {
  name          = "${var.name_prefix}-raw-crawler"
  role          = var.glue_role_arn
  database_name = aws_glue_catalog_database.tier["raw"].name
  schedule      = var.crawler_schedule

  s3_target {
    path = "s3://${var.raw_bucket_name}/"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })
}

locals {
  tiers = ["raw", "curated", "analytics"]
}

resource "aws_s3_bucket" "tier" {
  for_each = toset(local.tiers)
  bucket   = "${var.bucket_prefix}-${each.key}"
  tags     = merge(var.tags, { Name = "${var.bucket_prefix}-${each.key}", Tier = each.key })
}

resource "aws_s3_bucket_versioning" "tier" {
  for_each = aws_s3_bucket.tier
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tier" {
  for_each = aws_s3_bucket.tier
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tier" {
  for_each                = aws_s3_bucket.tier
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Raw lands cheap, then ages out to Glacier - curated/analytics are queried
# often so they stay on standard storage.
resource "aws_s3_bucket_lifecycle_configuration" "raw" {
  bucket = aws_s3_bucket.tier["raw"].id
  rule {
    id     = "raw-to-glacier"
    status = "Enabled"
    transition {
      days          = var.raw_glacier_transition_days
      storage_class = "GLACIER"
    }
  }
}

# Only the role that owns a given tier may write to it - enforced at the
# bucket-policy level, not just IAM, as defense in depth.
resource "aws_s3_bucket_policy" "tier" {
  for_each = aws_s3_bucket.tier
  bucket   = each.value.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = ["${each.value.arn}", "${each.value.arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "RestrictWriteToOwningRole"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:PutObject", "s3:DeleteObject"]
        Resource  = "${each.value.arn}/*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalArn" = lookup(var.tier_writer_role_arns, each.key, "arn:aws:iam::*:role/no-writer-configured")
          }
        }
      }
    ]
  })
}

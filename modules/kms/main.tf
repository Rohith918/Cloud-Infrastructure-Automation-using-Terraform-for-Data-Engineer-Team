resource "aws_kms_key" "this" {
  description             = var.key_description
  enable_key_rotation     = true
  deletion_window_in_days = var.deletion_window_days
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.key_alias}"
  target_key_id = aws_kms_key.this.key_id
}

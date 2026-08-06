# Provisions empty secret containers + access policy only. Actual values
# are populated out-of-band (rotation Lambda, manual entry, or a
# secrets-sync process) - Terraform never carries real secret values as
# plaintext variables, so nothing sensitive ever lands in state here.

resource "aws_secretsmanager_secret" "this" {
  for_each   = toset(var.secret_names)
  name       = "${var.name_prefix}/${each.key}"
  kms_key_id = var.kms_key_arn
  tags       = var.tags
}

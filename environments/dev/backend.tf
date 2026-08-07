terraform {
  backend "s3" {
    bucket         = "dataforge-terraform-state-nr"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "dataforge-terraform-locks"
    encrypt        = true
    # kms_key_id intentionally omitted here - bucket has default SSE-KMS via
    # bootstrap/state-backend, so every object inherits it automatically.
  }
}

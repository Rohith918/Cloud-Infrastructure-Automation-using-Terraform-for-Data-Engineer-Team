variable "aws_region" {
  description = "AWS region for the state backend"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally-unique S3 bucket name for Terraform state"
  type        = string
  default     = "dataforge-terraform-state-shared"
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "dataforge-terraform-locks"
}

variable "owner" {
  description = "Team/owner tag"
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center tag"
  type        = string
  default     = "data-platform"
}

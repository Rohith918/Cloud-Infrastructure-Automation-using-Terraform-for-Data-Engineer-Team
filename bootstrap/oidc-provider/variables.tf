variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "github_org" {
  description = "GitHub org/user that owns the dataforge repo"
  type        = string
}

variable "github_repo" {
  description = "Repo name"
  type        = string
  default     = "Cloud-Infrastructure-Automation-using-Terraform-for-Data-Engineer-Team"
}

variable "protected_environment_name" {
  description = "GitHub Actions 'environment' name with required reviewers, gating apply"
  type        = string
  default     = "prod"
}

variable "apply_role_policy_arn" {
  description = "ARN of the scoped IAM policy granting the apply role its actual permissions (create separately, do not use AdministratorAccess)"
  type        = string
}

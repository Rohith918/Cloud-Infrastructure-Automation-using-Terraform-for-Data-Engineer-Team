variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type    = string
  default = "platform-team"
}

variable "cost_center" {
  type    = string
  default = "data-platform"
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "admin_role_arn" {
  description = "IAM role ARN treated as the Lake Formation administrator (e.g. your CI apply role or a break-glass admin role)"
  type        = string
}

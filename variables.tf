variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment_name" {
  description = "Short name used in resource naming (single environment for this project)"
  type        = string
  default     = "smallbiz"
}

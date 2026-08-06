variable "bucket_prefix" {
  description = "e.g. dataforge-dev - tier name is appended (-raw, -curated, -analytics)"
  type        = string
}

variable "kms_key_arn" {
  type = string
}

variable "raw_glacier_transition_days" {
  type    = number
  default = 90
}

variable "tier_writer_role_arns" {
  description = "Map of tier name -> IAM role ARN allowed to write to that tier"
  type        = map(string)
  default     = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

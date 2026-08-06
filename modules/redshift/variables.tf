variable "namespace_name" {
  type = string
}

variable "workgroup_name" {
  type = string
}

variable "database_name" {
  type    = string
  default = "dataforge"
}

variable "kms_key_arn" {
  type = string
}

variable "spectrum_role_arn" {
  description = "IAM role Redshift Spectrum assumes to read the S3 data lake"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on 5439 (e.g. MWAA, BI tool)"
  type        = list(string)
}

variable "base_capacity_rpu" {
  type    = number
  default = 8
}

variable "tags" {
  type    = map(string)
  default = {}
}

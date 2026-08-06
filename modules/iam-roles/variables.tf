variable "name_prefix" {
  type = string
}

variable "raw_bucket_arn" {
  type = string
}

variable "curated_bucket_arn" {
  type = string
}

variable "analytics_bucket_arn" {
  type = string
}

variable "dag_bucket_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

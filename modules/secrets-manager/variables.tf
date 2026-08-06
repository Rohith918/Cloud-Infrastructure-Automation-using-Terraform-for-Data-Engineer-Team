variable "name_prefix" {
  type = string
}

variable "secret_names" {
  description = "e.g. [\"source-db-conn\", \"salesforce-api-key\"]"
  type        = list(string)
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "key_alias" {
  description = "Alias suffix, e.g. dataforge-dev-datalake"
  type        = string
}

variable "key_description" {
  type = string
}

variable "deletion_window_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}

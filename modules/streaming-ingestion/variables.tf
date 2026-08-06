variable "stream_name" {
  type = string
}

variable "shard_count" {
  type    = number
  default = 2
}

variable "retention_hours" {
  type    = number
  default = 24
}

variable "kms_key_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

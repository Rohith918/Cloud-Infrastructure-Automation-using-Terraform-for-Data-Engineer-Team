variable "name_prefix" {
  type = string
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "kinesis_stream_name" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

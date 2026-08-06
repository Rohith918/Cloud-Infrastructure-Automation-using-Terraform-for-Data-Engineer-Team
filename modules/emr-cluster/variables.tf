variable "cluster_name" {
  type = string
}

variable "release_label" {
  type    = string
  default = "emr-7.1.0"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "emr_service_role_arn" {
  type = string
}

variable "emr_instance_profile" {
  type = string
}

variable "log_uri" {
  type = string
}

variable "master_instance_type" {
  type    = string
  default = "m5.xlarge"
}

variable "core_instance_type" {
  type    = string
  default = "m5.xlarge"
}

variable "core_instance_count" {
  type    = number
  default = 2
}

variable "use_spot" {
  type    = bool
  default = true
}

variable "spot_bid_price" {
  type    = string
  default = "0.20"
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "environment_name" {
  type = string
}

variable "airflow_version" {
  type    = string
  default = "2.9.2"
}

variable "environment_class" {
  type    = string
  default = "mw1.small"
}

variable "execution_role_arn" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "MWAA requires exactly 2 private subnets in different AZs"
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

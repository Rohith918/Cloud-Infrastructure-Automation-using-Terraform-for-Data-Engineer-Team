variable "admin_role_arn" {
  description = "IAM role treated as the Lake Formation data lake administrator"
  type        = string
}

variable "glue_role_arn" {
  type = string
}

variable "database_names" {
  description = "Map of tier -> glue database name, from the glue-catalog module output"
  type        = map(string)
}

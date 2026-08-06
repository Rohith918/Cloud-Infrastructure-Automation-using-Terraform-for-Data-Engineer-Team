variable "name_prefix" {
  type = string
}

variable "glue_role_arn" {
  type = string
}

variable "raw_bucket_name" {
  type = string
}

variable "crawler_schedule" {
  description = "cron expression, e.g. cron(0 */6 * * ? *) for every 6 hours"
  type        = string
  default     = "cron(0 */6 * * ? *)"
}

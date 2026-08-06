output "emr_role_arn" {
  value = aws_iam_role.emr.arn
}

output "emr_instance_profile_name" {
  value = aws_iam_instance_profile.emr.name
}

output "mwaa_role_arn" {
  value = aws_iam_role.mwaa.arn
}

output "glue_role_arn" {
  value = aws_iam_role.glue.arn
}

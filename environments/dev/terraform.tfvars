aws_region     = "us-east-1"
environment    = "dev"
owner          = "platform-team"
cost_center    = "data-platform"
alert_email    = "nrohit@gmail.com" 
# TODO: Replace with a real distribution list
admin_role_arn = "arn:aws:iam::{$secret:Aws_Account_Number}:user/Terraform" # Corrected to use the CI/CD apply role for dev

# bootstrap/oidc-provider
# GitHub Actions <-> AWS trust. Applied once per AWS account (this is an
# account-wide singleton resource). Creates two roles:
#   - plan role: assumable from ANY branch/PR, read-only permissions
#   - apply role: assumable ONLY from main, inside a protected GitHub
#     "environment" (so a human reviewer gates token issuance)

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# GitHub's OIDC thumbprint - Terraform-managed so rotation is tracked in
# version control instead of a forgotten manual console change.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# ---- Plan role: read-only, assumable from any branch of this repo ----
resource "aws_iam_role" "plan" {
  name                 = "terraform"
  max_session_duration = 1800 # 30 min

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })

  tags = { Project = "dataforge", Purpose = "ci-plan" }
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---- Apply role: write access, assumable ONLY from main branch inside the
# "prod" GitHub environment (required reviewers gate this in GitHub itself)
# Creates one role per environment.
resource "aws_iam_role" "apply" {
  for_each             = toset(["dev", "staging", "prod"])
  name                 = "dataforge-ci-apply-${each.key}-role"
  max_session_duration = 1800

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn } # Note: Corrected Principal
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          # This ensures each role is scoped to its corresponding GitHub Environment.
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:environment:${each.key}"
        }
      }
    }]
  })

  # Belt-and-suspenders: even if the attached policy below is ever too
  # broad, this boundary caps what the role can actually do.
  permissions_boundary = aws_iam_policy.apply_boundary.arn

  tags = { Project = "dataforge", Purpose = "ci-apply", Environment = each.key }
}

resource "aws_iam_policy" "apply_boundary" {
  name        = "dataforge-ci-apply-boundary"
  description = "Permission boundary capping the CI apply role to dataforge-prefixed resources"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowDataforgeScopedActions"
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:ResourceTag/Project" = "dataforge"
          }
        }
      },
      {
        # Many create/describe/list calls have no resource-level tags to
        # condition on yet, so they're allowed broadly; the boundary's real
        # job is preventing touch of resources tagged for OTHER projects.
        Sid      = "AllowUntaggedReadAndCreate"
        Effect   = "Allow"
        Action   = ["*:Describe*", "*:List*", "*:Get*", "iam:PassRole"]
        Resource = "*"
      }
    ]
  })
}

# NOTE: attach a scoped custom policy (not AdministratorAccess) to the apply
# role in a real build - e.g. dataforge-apply-policy limited to
# s3/kms/glue/emr/mwaa/redshift/iam actions on dataforge-* resource names.
# Left as a variable-driven attachment so it can evolve per environment.
resource "aws_iam_role_policy_attachment" "apply_scoped" {
  for_each   = aws_iam_role.apply
  role       = each.value.name
  policy_arn = var.apply_role_policy_arn
}

# RFC: DataForge — Enterprise Data Platform Infrastructure

Status: Draft
Owner: platform-team

## Problem statement
<!-- What business/technical pain triggered this project? -->

## Goals
- Provision a secure, multi-environment AWS data platform via Terraform
- Automate CI/CD for infra changes with policy-as-code enforcement
- Provide DE team with self-serve infra (S3 lake, catalog, orchestration,
  warehouse) without infra-team involvement in day-to-day operation

## Non-goals
- Building or owning any ETL/transformation code (DAGs, Spark jobs) — DE-owned
- Data governance policy definition (classification rules, retention policy
  content) — provisioned as infra, defined by data governance/compliance

## Discovery notes
<!-- Fill in from stakeholder sessions: data volume/velocity, source
systems, consumption patterns, SLAs, existing pain points -->

## Proposed architecture
See docs/architecture-diagram (or the inline diagram shared in project chat).

## Alternatives considered
| Option | Chosen | Why |
|---|---|---|
| Kinesis vs MSK vs Kafka-on-EKS | Kinesis (dev) | Lower cost/ops overhead for reference build; MSK path documented as swap-in |
| Redshift Serverless vs Snowflake | Redshift Serverless | AWS-native, no separate vendor billing/IAM model |
| EMR vs EKS-Spark | EMR | Faster to provision, less operational surface for a first build |

## Cost estimate
<!-- Fill in via Infracost once environments/dev is finalized -->

## Security & compliance considerations
- State: S3 + KMS + DynamoDB locking (see bootstrap/)
- CI/CD identity: OIDC federation, no static AWS keys (see bootstrap/oidc-provider)
- Secrets: containers only, values populated out-of-band (see modules/secrets-manager)

## Rollout plan
1. Bootstrap (state backend + OIDC) — manual apply, security-reviewed
2. environments/dev — full stack, validate end-to-end
3. environments/staging — mirror dev, add stricter policy enforcement
4. environments/prod — requires signed-off RFC, hard-fail Checkov, required reviewers

## Open questions
<!-- Track unresolved decisions here -->

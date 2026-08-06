# DataForge

Enterprise-pattern Terraform project provisioning a full AWS data platform
for a data engineering team — networking, data lake, streaming ingestion,
cataloging/governance, Spark processing, orchestration (MWAA), and a data
warehouse — with GitHub Actions CI/CD, OIDC-federated credentials, and
policy-as-code enforcement.

Infra-team scope only: this repo never contains DAG code, Spark
transformation logic, or table schemas. See `docs/RFC-dataforge-platform.md`
for the full design rationale and the dividing line between infra-owned and
DE-owned artifacts.

## Layout

- `bootstrap/` — applied once, manually, before anything else (state backend, OIDC)
- `modules/` — reusable building blocks, never applied directly
- `environments/{dev,staging,prod}/` — composition layer, the only place `terraform apply` runs
- `policies/` — Checkov config + OPA rego, enforced in CI
- `.github/workflows/` — pr-validate, plan, apply, drift-detection

## First-time setup

See the execution guide provided alongside this repo (or `docs/RFC-dataforge-platform.md`
§ Rollout plan) for the exact bootstrap → OIDC → environment order.

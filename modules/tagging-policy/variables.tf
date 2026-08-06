# Not a resource module - imported for its variable validation. Every
# environment's main.tf declares mandatory_tags using this shape, and
# CI's OPA policy (policies/opa/mandatory-tags.rego) enforces the same
# four keys are present on every resource that supports tagging.

variable "mandatory_tags" {
  description = "Tags every dataforge resource must carry"
  type = object({
    Project           = string
    Environment       = string
    Owner             = string
    CostCenter        = string
    DataClassification = string
  })

  validation {
    condition     = contains(["dev", "staging", "prod"], var.mandatory_tags.Environment)
    error_message = "Environment tag must be one of: dev, staging, prod."
  }

  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.mandatory_tags.DataClassification)
    error_message = "DataClassification tag must be one of: public, internal, confidential, restricted."
  }
}

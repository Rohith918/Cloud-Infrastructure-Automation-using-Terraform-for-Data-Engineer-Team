package terraform.tagging

# Enforced via conftest in CI (or Sentinel on Terraform Cloud). Fails the
# plan if any taggable resource is missing one of the four mandatory tags.

required_tags := {"Project", "Environment", "Owner", "CostCenter", "DataClassification"}

deny[msg] {
  resource := input.resource_changes[_]
  resource.change.after.tags
  missing := required_tags - {tag | resource.change.after.tags[tag]}
  count(missing) > 0
  msg := sprintf(
    "%s is missing mandatory tags: %v",
    [resource.address, missing]
  )
}

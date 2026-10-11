output "registry_url" {
  description = "HTTPS URL of the registry web UI and API."
  value       = module.registry.registry_url
}

output "registry_client_role_arns" {
  description = <<-EOT
    Role ARN for each module repository. Pass it to aws-actions/configure-aws-credentials as
    `role-to-assume` in that repository's release workflow.
  EOT
  value       = module.registry.registry_client_role_arns
}

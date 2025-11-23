# Add your outputs here

output "registry_url" {
  description = "HTTPS URL of the Terraform registry"
  value       = local.registry_url
}

output "registry_client_role_names" {
  description = "Map of repository names to their IAM role names for registry clients"
  value = {
    for repo in var.terraform_modules :
    repo => module.registry-client-roles[repo].github_role_name
  }
}

output "registry_client_role_arns" {
  description = "Map of repository names to their IAM role ARNs for registry clients"
  value = {
    for repo in var.terraform_modules :
    repo => module.registry-client-roles[repo].github_role_arn
  }
}

output "bucket_arn" {
  description = "ARN of the S3 bucket used for the Terraform registry"
  value       = module.terraform-registry-bucket.bucket_arn
}

output "bucket_name" {
  description = "Name of the S3 bucket used for the Terraform registry"
  value       = module.terraform-registry-bucket.bucket_name
}

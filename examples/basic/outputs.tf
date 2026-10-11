output "registry_url" {
  description = "HTTPS URL of the registry web UI and API."
  value       = module.registry.registry_url
}

output "bucket_name" {
  description = "S3 bucket that stores module archives."
  value       = module.registry.bucket_name
}

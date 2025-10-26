locals {
  module_version = "0.2.0"

  service_name = "terraform-registry"

  default_module_tags = {
    environment : var.environment
    service : local.service_name
    created_by_module : "infrahouse/registry/aws"
  }

  dynamodb_tables         = ["DeployKeys", "Modules", "Providers", "Reports"]
  registry_url            = "https://${module.ecs.dns_hostnames[0]}"
  cognito_issuer          = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"
  minimum_password_length = 21
}

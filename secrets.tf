module "registry_client_secret" {
  source             = "registry.infrahouse.com/infrahouse/secret/aws"
  version            = "1.1.0"
  environment        = var.environment
  secret_name_prefix = "registry-client-secret"
  secret_description = "Oauth2 credentials with Google"
  secret_value       = aws_cognito_user_pool_client.this.client_secret
  readers = [
    module.ecs.task_execution_role_arn
  ]
  tags = local.default_module_tags
}

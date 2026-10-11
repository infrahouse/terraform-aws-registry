provider "aws" {
  region = var.region
}

module "registry" {
  source  = "registry.infrahouse.com/infrahouse/registry/aws"
  version = "0.5.0"

  providers = {
    aws = aws
  }

  environment = var.environment

  # The ALB goes to the public subnets, the ECS container instances to the private ones.
  subnets_frontend = var.subnets_frontend
  subnets_backend  = var.subnets_backend

  # The registry is published as registry.<zone name>.
  zone_id = var.zone_id

  # Cognito emails each user a temporary password and adds them to the admin group.
  cognito_users = var.cognito_users
}

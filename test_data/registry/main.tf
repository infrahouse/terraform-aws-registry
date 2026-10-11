data "aws_region" "current" {}

locals {
  # The replica must live in a region other than the one the test runs in.
  replication_region = data.aws_region.current.region == "us-east-1" ? "us-west-1" : "us-east-1"
}

module "registry" {
  source = "./../../"
  providers = {
    aws = aws
  }
  environment      = "development"
  subnets_backend  = var.backend_subnets
  subnets_frontend = var.frontend_subnets
  zone_id          = var.zone_id

  access_log_force_destroy = true
  replication_region       = local.replication_region

  cognito_users = [
    {
      email     = "aleks@infrahouse.com"
      full_name = "Aleks"
    }
  ]
}

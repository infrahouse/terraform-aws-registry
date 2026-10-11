provider "aws" {
  region = var.region
}

# The registry client roles trust GitHub Actions through OIDC, so the account needs a GitHub OIDC
# identity provider. Create it once per account, for instance with
# https://github.com/infrahouse/terraform-aws-gh-identity-provider
module "registry" {
  source  = "registry.infrahouse.com/infrahouse/registry/aws"
  version = "0.5.0"

  providers = {
    aws = aws
  }

  environment      = var.environment
  subnets_frontend = var.subnets_frontend
  subnets_backend  = var.subnets_backend
  zone_id          = var.zone_id
  cognito_users    = var.cognito_users

  # Module archives are replicated to this region.
  replication_region = var.replication_region

  # One IAM role per module repository. A release workflow in the repository assumes the role,
  # reads the module's deploy key from DynamoDB, and uploads the module with `ih-registry upload`.
  gh_org_name       = var.gh_org_name
  terraform_modules = var.terraform_modules
}

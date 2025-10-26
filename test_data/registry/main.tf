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

  cognito_users = [
    {
      email     = "aleks@infrahouse.com"
      full_name = "Aleks"
    }
  ]
}

# Add your main resources here
module "ecs" {
  source  = "registry.infrahouse.com/infrahouse/ecs/aws"
  version = "5.12.0"
  providers = {
    aws     = aws
    aws.dns = aws
  }
  asg_subnets = var.subnets_backend
  ami_id      = data.aws_ami.ecs_latest.id
  dns_names = [
    var.registry_hostname
  ]
  docker_image                      = "pacovk/tapir:0.7.0"
  internet_gateway_id               = data.aws_internet_gateway.main.id
  load_balancer_subnets             = var.subnets_frontend
  service_name                      = local.service_name
  zone_id                           = var.zone_id
  enable_container_insights         = true
  enable_cloudwatch_logs            = true
  task_min_count                    = var.task_min_count
  task_max_count                    = var.task_max_count
  on_demand_base_capacity           = var.on_demand_base_capacity
  healthcheck_response_code_matcher = "302"
  container_memory                  = "256"
  container_healthcheck_command     = "/usr/bin/pkill -0 java || exit 1"
  access_log_force_destroy          = var.access_log_force_destroy
  task_environment_variables = [
    {
      name : "AUTH_ENDPOINT"
      value : local.cognito_issuer
    },
    {
      name : "AUTH_CLIENT_ID"
      value : aws_cognito_user_pool_client.this.id
    },
    {
      name : "AUTH_ROLE_SOURCE"
      value : "idtoken"
    },
    {
      name : "QUARKUS_OIDC_ROLES_SOURCE"
      value : "idtoken"
    },
    {
      name : "QUARKUS_OIDC_ROLES_ROLE_CLAIM_PATH"
      value : "cognito:groups"
    },
    {
      name : "QUARKUS_OIDC_AUTHENTICATION_FORCE_REDIRECT_HTTPS_SCHEME"
      value : true
    },
    {
      name : "AWS_REGION",
      value : data.aws_region.current.name
    },
    {
      name : "STORAGE_CONFIG"
      value : "s3"
    },
    {
      name : "S3_STORAGE_BUCKET_NAME"
      value : module.terraform-registry-bucket.bucket_name
    },
    {
      name : "S3_STORAGE_BUCKET_REGION"
      value : data.aws_region.current.name
    },
    {
      name : "REGISTRY_HOSTNAME"
      value : "registry.${data.aws_route53_zone.zone.name}"
    },
    {
      name : "REGISTRY_PORT"
      value : 443
    },
  ]
  task_secrets = [
    {
      name : "AUTH_CLIENT_SECRET"
      valueFrom : module.registry_client_secret.secret_arn
    },
  ]
  container_command = [
    "-Dquarkus.http.host=0.0.0.0",
    "-Dquarkus.http.cors=true",
    "-Dquarkus.http.cors.origins=${local.registry_url}",
    "-jar",
    "/tf/registry/tapir.jar"
  ]
  task_role_arn = aws_iam_role.registry-node.arn
  tags          = local.default_module_tags
}

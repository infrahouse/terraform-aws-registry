variable "region" {
  description = "AWS region to deploy the registry in."
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name, for example `production`. Goes to the `environment` tag."
  type        = string
}

variable "subnets_frontend" {
  description = "Public subnet IDs for the load balancer. Use at least two availability zones."
  type        = list(string)
}

variable "subnets_backend" {
  description = "Private subnet IDs for the ECS container instances."
  type        = list(string)
}

variable "zone_id" {
  description = "Route53 hosted zone ID. The registry is published as `registry.<zone name>`."
  type        = string
}

variable "cognito_users" {
  description = "Users who can sign in to the registry web UI."
  type = list(
    object(
      {
        email     = string
        full_name = string
      }
    )
  )
}

variable "gh_org_name" {
  description = "GitHub organization that owns the module repositories."
  type        = string
}

variable "terraform_modules" {
  description = <<-EOT
    Repositories that publish modules to the registry, for example `terraform-aws-key`.
    Each one gets an IAM role its release workflow can assume.
  EOT
  type        = list(string)
}

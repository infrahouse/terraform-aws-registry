variable "access_log_force_destroy" {
  description = "Destroy S3 bucket with access logs even if non-empty"
  type        = bool
  default     = false
}

variable "cognito_users" {
  description = "List of Cognito users to create with email, full name, and password"
  type = list(
    object(
      {
        email     = string
        full_name = string
      }
    )
  )
}

variable "environment" {
  description = "Environment name (e.g., development, staging, production)"
  type        = string
}

variable "on_demand_base_capacity" {
  description = "Minimum number of on-demand instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "subnets_backend" {
  description = "List of subnet IDs for ECS instances and backend services"
  type        = list(string)
}

variable "subnets_frontend" {
  description = "List of subnet IDs for the load balancer"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "zone_id" {
  description = "Route53 hosted zone ID for DNS records"
  type        = string
}

variable "task_min_count" {
  description = "Minimum number of ECS tasks to run"
  type        = number
  default     = 2
}

variable "task_max_count" {
  description = "Maximum number of ECS tasks to run"
  type        = number
  default     = 10
}

variable "terraform_modules" {
  description = "List of GitHub repository names that host Terraform modules for which to create registry client IAM roles. E.g. terraform-aws-actions-runner"
  type        = list(string)
  default     = []
}

variable "gh_org_name" {
  description = "GitHub organization name that owns the Terraform module repositories"
  type        = string
  default     = "infrahouse"
}

variable "registry_hostname" {
  description = "Hostname for the Terraform registry (will be combined with the Route53 zone)"
  type        = string
  default     = "registry"
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "terraform-registry"
}

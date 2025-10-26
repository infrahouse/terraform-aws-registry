# Terraform AWS Registry (Tapir + Cognito)


[![InfraHouse](https://img.shields.io/badge/InfraHouse-Terraform_Module-blue?style=for-the-badge&logo=terraform)](https://registry.terraform.io/namespaces/infrahouse)
[![License](https://img.shields.io/github/license/infrahouse/terraform-aws-registry?style=for-the-badge)](LICENSE)
[![AWS Cognito](https://img.shields.io/badge/Auth-AWS_Cognito-orange?style=for-the-badge&logo=amazonaws)](https://aws.amazon.com/cognito/)
[![Tapir](https://img.shields.io/badge/Backend-Tapir-lightgrey?style=for-the-badge&logo=open-source-initiative)](https://github.com/PacoVK/tapir)
[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/infrahouse/terraform-aws-registry/ci.yml?style=for-the-badge&logo=githubactions&label=CI)](https://github.com/infrahouse/terraform-aws-registry/actions)

A Terraform module that provisions a self-hosted Terraform Registry powered by [Tapir](https://github.com/PacoVK/tapir)
and authenticated through Amazon Cognito instead of Keycloak.

This module is ideal for organizations that want a lightweight, 
standards-compliant Terraform Registry integrated into AWS-native authentication 
without running a heavy Keycloak cluster.

# 🏗️ Overview

This module deploys the open-source Tapir Terraform Registry inside your AWS environment, complete with:

* **Tapir application** — packaged in a container, served via AWS ECS.
* **Cognito User Pool** — used as both user database and OIDC Identity Provider (IdP).
* **Application Load Balancer** with HTTPS termination; health checks automatically configured for Tapir.
* ACM SSL certificate, Route 53 DNS record, and CloudWatch logs integration.

Once deployed, the registry is available at a URL composed of:
* **Hostname**: Configurable via `registry_hostname` variable (defaults to `registry`)
* **Domain**: Your Route53 hosted zone (specified via `zone_id` variable)

**Example**: If your Route53 zone is `example.com` and you use the default hostname, the registry will be accessible at `https://registry.example.com`

# 🔐 Authentication

Instead of Keycloak, this module configures a managed Amazon Cognito user pool as your IdP.

**Flow**

* A user accesses the Tapir registry URL (https://registry.example.com).
* Tapir redirects them to the Cognito Hosted UI.
* Cognito authenticates the user (email/password).
* Cognito returns an ID token containing:
```json
{
  "cognito:groups": ["admin"],
  "email": "user@example.com"
}
```
* Tapir and Quarkus read the `cognito:groups` claim from the ID token and authorize access - regular or privileged user

**Role mapping**
* The module creates a Cognito user group called `admin`
* Users are created based on the `cognito_users` variable (list of email addresses and names)
* All users specified in `cognito_users` are automatically added to the `admin` group
* Cognito automatically inserts the `cognito:groups` claim into ID tokens for users who are members of the admin group
* Tapir reads the `cognito:groups` claim to determine the user's access level (admin vs regular user)


# ⚙️ Key Features

* Cognito OIDC integration with automatic app-client, domain, and redirect-URI setup.
* Tapir automatically configured for Cognito:
  * `AUTH_ENDPOINT`, `AUTH_CLIENT_ID`, `AUTH_CLIENT_SECRET` injected via environment variables.
  * Proper `QUARKUS_OIDC_ROLES_*` settings for role recognition.
* ALB health checks configured to accept HTTP 302 responses (redirect to Cognito login) as healthy
  * Note: Tapir doesn't currently include the SmallRye Health endpoints (`/q/health/ready`) in Quarkus; future enhancement could add a proper health endpoint

# 🚀 Usage Example

```hcl
module "terraform-registry" {
  source  = "infrahouse/registry/aws"
  version = "0.2.0"

  environment      = "development"

  # Networking
  subnets_backend  = var.backend_subnets
  subnets_frontend = var.frontend_subnets
  zone_id          = var.zone_id

  # Create Cognito users
  cognito_users = [
    {
      email     = "aleks@infrahouse.com"
      full_name = "Aleks"
    }
  ]
}
```
After you apply the Terraform configuration, Cognito automatically sends an email to each user 
specified in `cognito_users` with a **temporary password**.

When the user visits the registry (for example, https://registry.example.com) and signs in for the first time, 
Cognito will prompt them to set a new **permanent password** before granting access.

Once the password is changed, the user is redirected back to Tapir and can immediately use the private Terraform Registry.
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.62, < 7.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.62, < 7.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs"></a> [ecs](#module\_ecs) | registry.infrahouse.com/infrahouse/ecs/aws | 5.12.0 |
| <a name="module_registry-client-roles"></a> [registry-client-roles](#module\_registry-client-roles) | registry.infrahouse.com/infrahouse/github-role/aws | 1.4.0 |
| <a name="module_registry_client_secret"></a> [registry\_client\_secret](#module\_registry\_client\_secret) | registry.infrahouse.com/infrahouse/secret/aws | 1.1.0 |
| <a name="module_terraform-registry-bucket"></a> [terraform-registry-bucket](#module\_terraform-registry-bucket) | registry.infrahouse.com/infrahouse/s3-bucket/aws | 0.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cognito_user.users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user) | resource |
| [aws_cognito_user_group.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_group) | resource |
| [aws_cognito_user_in_group.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_in_group) | resource |
| [aws_cognito_user_pool.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_domain) | resource |
| [aws_dynamodb_table.registry_tables](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.registry-client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.registry_node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.registry-node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.registry-client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [random_password.users](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_ami.ecs_latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.registry-client-permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.registry_node_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.registry_node_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_internet_gateway.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/internet_gateway) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnet.frontend_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_log_force_destroy"></a> [access\_log\_force\_destroy](#input\_access\_log\_force\_destroy) | Destroy S3 bucket with access logs even if non-empty | `bool` | `false` | no |
| <a name="input_cognito_users"></a> [cognito\_users](#input\_cognito\_users) | List of Cognito users to create with email, full name, and password | <pre>list(<br/>    object(<br/>      {<br/>        email     = string<br/>        full_name = string<br/>      }<br/>    )<br/>  )</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., development, staging, production) | `string` | n/a | yes |
| <a name="input_gh_org_name"></a> [gh\_org\_name](#input\_gh\_org\_name) | GitHub organization name that owns the Terraform module repositories | `string` | `"infrahouse"` | no |
| <a name="input_on_demand_base_capacity"></a> [on\_demand\_base\_capacity](#input\_on\_demand\_base\_capacity) | Minimum number of on-demand instances in the Auto Scaling Group | `number` | `1` | no |
| <a name="input_registry_hostname"></a> [registry\_hostname](#input\_registry\_hostname) | Hostname for the Terraform registry (will be combined with the Route53 zone) | `string` | `"registry"` | no |
| <a name="input_subnets_backend"></a> [subnets\_backend](#input\_subnets\_backend) | List of subnet IDs for ECS instances and backend services | `list(string)` | n/a | yes |
| <a name="input_subnets_frontend"></a> [subnets\_frontend](#input\_subnets\_frontend) | List of subnet IDs for the load balancer | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_task_max_count"></a> [task\_max\_count](#input\_task\_max\_count) | Maximum number of ECS tasks to run | `number` | `10` | no |
| <a name="input_task_min_count"></a> [task\_min\_count](#input\_task\_min\_count) | Minimum number of ECS tasks to run | `number` | `2` | no |
| <a name="input_terraform_modules"></a> [terraform\_modules](#input\_terraform\_modules) | List of GitHub repository names that host Terraform modules for which to create registry client IAM roles. E.g. terraform-aws-actions-runner | `list(string)` | `[]` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Route53 hosted zone ID for DNS records | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_registry_client_role_arns"></a> [registry\_client\_role\_arns](#output\_registry\_client\_role\_arns) | Map of repository names to their IAM role ARNs for registry clients |
| <a name="output_registry_client_role_names"></a> [registry\_client\_role\_names](#output\_registry\_client\_role\_names) | Map of repository names to their IAM role names for registry clients |
| <a name="output_registry_url"></a> [registry\_url](#output\_registry\_url) | HTTPS URL of the Terraform registry |

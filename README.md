# terraform-aws-registry

[![Need Help?](https://img.shields.io/badge/Need%20Help%3F-Contact%20Us-0066CC)](https://infrahouse.com/contact)
[![Docs](https://img.shields.io/badge/docs-github.io-blue)](https://infrahouse.github.io/terraform-aws-registry/)
[![Registry](https://img.shields.io/badge/Terraform-Registry-purple?logo=terraform)](https://registry.terraform.io/modules/infrahouse/registry/aws/latest)
[![Release](https://img.shields.io/github/release/infrahouse/terraform-aws-registry.svg)](https://github.com/infrahouse/terraform-aws-registry/releases/latest)
[![AWS ECS](https://img.shields.io/badge/AWS-ECS-orange?logo=amazonecs)](https://aws.amazon.com/ecs/)
[![AWS Cognito](https://img.shields.io/badge/AWS-Cognito-orange?logo=amazonwebservices)](https://aws.amazon.com/cognito/)
[![AWS S3](https://img.shields.io/badge/AWS-S3-orange?logo=amazons3)](https://aws.amazon.com/s3/)
[![AWS DynamoDB](https://img.shields.io/badge/AWS-DynamoDB-orange?logo=amazondynamodb)](https://aws.amazon.com/dynamodb/)
[![Security](https://img.shields.io/github/actions/workflow/status/infrahouse/terraform-aws-registry/vuln-scanner-pr.yml?label=Security)](https://github.com/infrahouse/terraform-aws-registry/actions/workflows/vuln-scanner-pr.yml)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

A Terraform module that runs a private Terraform module registry in your AWS account. The registry is
[Tapir](https://github.com/PacoVK/tapir), an open-source implementation of the Terraform registry protocol. It runs
on ECS behind an Application Load Balancer, and admins sign in to its web UI through Amazon Cognito.

## Why This Module?

Tapir ships with Keycloak as its identity provider. Running Keycloak means another stateful service to patch,
back up, and keep highly available — just to let a handful of people sign in to a registry UI. This module
replaces it with a managed Cognito user pool and wires everything Tapir needs around it:

- **No identity server to operate** — Cognito is the user database and the OIDC provider
- **Storage that needs no care** — module archives in S3, metadata in DynamoDB with point-in-time recovery
- **Keyless publishing from CI** — one IAM role per module repository that GitHub Actions assumes through OIDC
- **Production defaults** — HTTPS with an ACM certificate, a DNS record, CloudWatch logs kept 365 days,
  and at least two Tapir tasks

## Features

- Tapir registry on ECS (EC2 launch type) with auto scaling between `task_min_count` and `task_max_count` tasks
- Internet-facing ALB with an ACM certificate and a Route 53 record, `registry.<your zone>` by default
- Cognito user pool, hosted sign-in domain, and OIDC app client, configured for Tapir
- Cognito users created from a list of emails and added to the `admin` group
- Cognito app client secret stored in Secrets Manager and readable only by the ECS task execution role
- S3 bucket for module archives; DynamoDB tables for modules, providers, reports, and deploy keys
- IAM roles for GitHub Actions that let a module repository read its deploy key and publish releases
- Container Insights and CloudWatch Logs with 365-day retention

## Quick Start

```hcl
module "registry" {
  source  = "registry.infrahouse.com/infrahouse/registry/aws"
  version = "0.5.0"

  providers = {
    aws = aws
  }

  environment      = "production"
  subnets_frontend = ["subnet-public-a", "subnet-public-b"]
  subnets_backend  = ["subnet-private-a", "subnet-private-b"]
  zone_id          = "Z1234567890ABC"

  cognito_users = [
    {
      email     = "admin@example.com"
      full_name = "Jane Admin"
    }
  ]
}
```

With a zone named `example.com` the registry comes up at `https://registry.example.com`. Each user in
`cognito_users` gets an email from Cognito with a temporary password; on first sign-in Cognito asks them to set a
permanent one.

To publish modules from GitHub Actions, list the module repositories in `terraform_modules` and create a deploy
key for each module in the Tapir UI. Consumers need no credentials:

```hcl
module "key" {
  source  = "registry.example.com/example/key/aws"
  version = "1.0.0"
}
```

## Architecture

![Terraform Registry Architecture](docs/assets/architecture.png)

## Documentation

Full documentation is available at
[infrahouse.github.io/terraform-aws-registry](https://infrahouse.github.io/terraform-aws-registry/).

- [Getting Started](https://infrahouse.github.io/terraform-aws-registry/getting-started/) — prerequisites, first
  deployment, first published module
- [Architecture](https://infrahouse.github.io/terraform-aws-registry/architecture/) — components, sign-in,
  download, and publishing flows
- [Configuration](https://infrahouse.github.io/terraform-aws-registry/configuration/) — every variable and output
- [Examples](https://infrahouse.github.io/terraform-aws-registry/examples/) — common deployment scenarios
- [Security](https://infrahouse.github.io/terraform-aws-registry/security/) — who can read, publish, and administer
  modules
- [Troubleshooting](https://infrahouse.github.io/terraform-aws-registry/troubleshooting/) — common issues and
  their fixes

## Usage

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.68.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ecs"></a> [ecs](#module\_ecs) | registry.infrahouse.com/infrahouse/ecs/aws | 6.1.0 |
| <a name="module_registry-client-roles"></a> [registry-client-roles](#module\_registry-client-roles) | registry.infrahouse.com/infrahouse/github-role/aws | 1.6.0 |
| <a name="module_registry_client_secret"></a> [registry\_client\_secret](#module\_registry\_client\_secret) | registry.infrahouse.com/infrahouse/secret/aws | 1.1.1 |
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
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Name of the service | `string` | `"terraform-registry"` | no |
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
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the S3 bucket used for the Terraform registry |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | Name of the S3 bucket used for the Terraform registry |
| <a name="output_registry_client_role_arns"></a> [registry\_client\_role\_arns](#output\_registry\_client\_role\_arns) | Map of repository names to their IAM role ARNs for registry clients |
| <a name="output_registry_client_role_names"></a> [registry\_client\_role\_names](#output\_registry\_client\_role\_names) | Map of repository names to their IAM role names for registry clients |
| <a name="output_registry_url"></a> [registry\_url](#output\_registry\_url) | HTTPS URL of the Terraform registry |
<!-- END_TF_DOCS -->

## Examples

See the [`examples/`](examples/) directory for complete working examples:

- [`examples/basic`](examples/basic) — a registry with Cognito users
- [`examples/module-publishing`](examples/module-publishing) — a registry plus IAM roles for module repositories
  that publish from GitHub Actions

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the Apache 2.0 License — see the [LICENSE](LICENSE) file for details.

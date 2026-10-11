# terraform-aws-registry

A Terraform module that runs a private Terraform module registry in your AWS account. The registry is
[Tapir](https://github.com/PacoVK/tapir), an open-source implementation of the Terraform registry protocol. It runs
on ECS behind an Application Load Balancer, and admins sign in to its web UI through Amazon Cognito.

## Why This Module?

Tapir ships with Keycloak as its identity provider. Running Keycloak means another stateful service to patch,
back up, and keep highly available — just to let a handful of people sign in to a registry UI. This module
replaces it with a managed Cognito user pool and wires everything Tapir needs around it:

- **No identity server to operate** — Cognito is the user database and the OIDC provider
- **Storage that needs no care** — module archives in S3, replicated to a second region; metadata in
  DynamoDB with point-in-time recovery
- **Keyless publishing from CI** — one IAM role per module repository that GitHub Actions assumes through OIDC
- **Production defaults** — HTTPS with an ACM certificate, a DNS record, CloudWatch logs kept 365 days,
  and at least two Tapir tasks

## Features

- Tapir registry on ECS (EC2 launch type) with auto scaling between `task_min_count` and `task_max_count` tasks
- Internet-facing ALB with an ACM certificate and a Route 53 record, `registry.<your zone>` by default
- Cognito user pool, hosted sign-in domain, and OIDC app client, configured for Tapir
- Cognito users created from a list of emails and added to the `admin` group
- Cognito app client secret stored in Secrets Manager and readable only by the ECS task execution role
- S3 bucket for module archives with cross-region replication; DynamoDB tables for modules, providers,
  reports, and deploy keys
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

  replication_region = "us-east-1"

  cognito_users = [
    {
      email     = "admin@example.com"
      full_name = "Jane Admin"
    }
  ]
}
```

With a zone named `example.com` the registry comes up at `https://registry.example.com`. Each user gets an email
from Cognito with a temporary password; on first sign-in Cognito asks them to set a permanent one.

See [Getting Started](getting-started.md) for the full walkthrough, including publishing your first module.

## Architecture

![Terraform Registry Architecture](assets/architecture.png)

## How It Works

Terraform finds the registry through `https://registry.<zone>/.well-known/terraform.json` and lists module
versions through the Tapir API. Reading modules needs no credentials: Tapir answers a download request with a
pre-signed S3 URL, and Terraform fetches the archive straight from the bucket.

The web UI is different. Tapir redirects every browser request to the Cognito hosted sign-in page, and only users
in the `admin` group get in. Admins use the UI to browse modules and to create deploy keys.

A deploy key is what lets a module be published. A module repository's release workflow assumes its registry
client role, reads the module's deploy key from the `DeployKeys` table, and uploads a zip of the module to Tapir.
See [Architecture](architecture.md) for each flow in detail.

## Documentation

- [Getting Started](getting-started.md) — prerequisites, first deployment, first published module
- [Architecture](architecture.md) — components, request flows, and the publishing flow
- [Configuration](configuration.md) — every variable and output explained
- [Examples](examples.md) — common deployment scenarios
- [Security](security.md) — authentication, access to modules, and what to protect
- [Troubleshooting](troubleshooting.md) — common issues and their fixes
- [Upgrading](upgrading.md) — breaking changes between versions
- [Changelog](changelog.md) — release history

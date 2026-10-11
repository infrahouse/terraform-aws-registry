# Examples

Runnable versions of the first two examples live in the
[`examples/`](https://github.com/infrahouse/terraform-aws-registry/tree/main/examples) directory of the repository.

## Basic Registry

A registry with one admin, published at `registry.<zone>`.

```hcl
module "registry" {
  source  = "registry.infrahouse.com/infrahouse/registry/aws"
  version = "0.5.0"

  providers = {
    aws = aws
  }

  environment      = "production"
  subnets_frontend = module.network.subnet_public_ids
  subnets_backend  = module.network.subnet_private_ids
  zone_id          = aws_route53_zone.example.zone_id

  replication_region = "us-east-1"

  cognito_users = [
    {
      email     = "admin@example.com"
      full_name = "Jane Admin"
    }
  ]
}

output "registry_url" {
  value = module.registry.registry_url
}
```

## Publishing Modules from GitHub Actions

Every repository in `terraform_modules` gets an IAM role its release workflow can assume.

```hcl
module "registry" {
  source  = "registry.infrahouse.com/infrahouse/registry/aws"
  version = "0.5.0"

  providers = {
    aws = aws
  }

  environment      = "production"
  subnets_frontend = module.network.subnet_public_ids
  subnets_backend  = module.network.subnet_private_ids
  zone_id          = aws_route53_zone.example.zone_id

  replication_region = "us-east-1"

  cognito_users = [
    {
      email     = "admin@example.com"
      full_name = "Jane Admin"
    }
  ]

  gh_org_name = "example"
  terraform_modules = [
    "terraform-aws-key",
    "terraform-aws-secret",
  ]
}

output "registry_client_role_arns" {
  value = module.registry.registry_client_role_arns
}
```

In each module repository, a workflow like this one publishes every tag. Use the role ARN for that repository
and the region where the registry runs:

```yaml
name: Publish module

on:  # yamllint disable-line rule:truthy
  push:
    tags:
      - "*"

permissions:
  id-token: write
  contents: read

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: arn:aws:iam::123456789012:role/ih-tf-terraform-aws-key-github
          aws-region: us-west-2

      - uses: actions/setup-python@v6
        with:
          python-version: "3.13"

      - run: pip install infrahouse-toolkit

      - run: |
          ih-registry upload \
            --registry-url https://registry.example.com \
            --module-name example/key/aws \
            --module-version "${{ github.ref_name }}"
```

Before the first release, create a deploy key for `example/key/aws` in the Tapir UI.

## Custom Hostname and Service Name

Publish the registry as `terraform.example.com`, and give the Cognito resources a different prefix — for
instance because the default Cognito domain `terraform-registry-<region>` is already taken by another account.

```hcl
module "registry" {
  source  = "registry.infrahouse.com/infrahouse/registry/aws"
  version = "0.5.0"

  providers = {
    aws = aws
  }

  environment       = "production"
  registry_hostname = "terraform"
  service_name      = "example-terraform-registry"

  subnets_frontend = module.network.subnet_public_ids
  subnets_backend  = module.network.subnet_private_ids
  zone_id          = aws_route53_zone.example.zone_id

  replication_region = "us-east-1"

  cognito_users = [
    {
      email     = "admin@example.com"
      full_name = "Jane Admin"
    }
  ]
}
```

## Fixed Capacity on On-Demand Instances

Run exactly two Tapir tasks and make the first two container instances on-demand, so AWS cannot reclaim them
the way it reclaims spot instances.

```hcl
module "registry" {
  source  = "registry.infrahouse.com/infrahouse/registry/aws"
  version = "0.5.0"

  providers = {
    aws = aws
  }

  environment      = "production"
  subnets_frontend = module.network.subnet_public_ids
  subnets_backend  = module.network.subnet_private_ids
  zone_id          = aws_route53_zone.example.zone_id

  replication_region = "us-east-1"

  task_min_count          = 2
  task_max_count          = 2
  on_demand_base_capacity = 2

  cognito_users = [
    {
      email     = "admin@example.com"
      full_name = "Jane Admin"
    }
  ]
}
```

## Using Modules from the Registry

The module source is `<registry hostname>/<namespace>/<name>/<provider>`. Downloads need no credentials:

```hcl
module "key" {
  source  = "registry.example.com/example/key/aws"
  version = "1.0.0"
}
```

List the published versions of a module with the registry API:

```bash
curl https://registry.example.com/terraform/modules/v1/example/key/aws/versions
```

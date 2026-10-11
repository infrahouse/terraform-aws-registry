# Getting Started

This page takes you from an existing VPC to a running registry, a first published module, and a `terraform init`
that downloads it.

## Prerequisites

- **Terraform** `~> 1.8` and the **AWS provider** `~> 6.0`
- **A VPC** with an internet gateway attached. The module looks the gateway up from the VPC of the first
  frontend subnet.
- **Public subnets** for the load balancer, in at least two availability zones
- **Private subnets with outbound internet access** (a NAT gateway) for the ECS container instances. They pull
  the Tapir image from Docker Hub and talk to Cognito, S3, DynamoDB, and Secrets Manager.
- **A public Route 53 hosted zone** in the same AWS account. The module creates the registry's DNS record and
  validates its ACM certificate there.
- **For publishing from GitHub Actions:** a GitHub OIDC identity provider in the account, created once per
  account, for instance with
  [terraform-aws-gh-identity-provider](https://github.com/infrahouse/terraform-aws-gh-identity-provider)

!!! note "One registry per account and region"
    The DynamoDB tables have fixed names: `DeployKeys`, `Modules`, `Providers`, and `Reports`. A second registry
    in the same account and region would collide with the first.

If you need a VPC, [terraform-aws-service-network](https://github.com/infrahouse/terraform-aws-service-network)
creates one with public and private subnets.

## Step 1: Deploy the Registry

```hcl
provider "aws" {
  region = "us-west-2"
}

module "registry" {
  source  = "registry.infrahouse.com/infrahouse/registry/aws"
  version = "0.4.0"

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

output "registry_url" {
  value = module.registry.registry_url
}
```

```bash
terraform init
terraform apply
```

The first apply takes several minutes: ACM validates the certificate through DNS, the Auto Scaling group launches
the container instances, and ECS starts the Tapir tasks.

## Step 2: Sign In

Cognito emails every user in `cognito_users` a temporary password. The email comes from
`no-reply@verificationemail.com` — check the spam folder if it does not arrive.

1. Open the registry URL, for example `https://registry.example.com`.
2. Tapir redirects you to the Cognito sign-in page. Sign in with your email and the temporary password.
3. Cognito asks for a permanent password: at least 21 characters, with upper- and lower-case letters, a number,
   and a symbol.
4. Cognito sends you back to the Tapir UI.

## Step 3: Check the Registry API

The registry protocol endpoints do not need a sign-in, so `curl` is enough:

```bash
curl https://registry.example.com/.well-known/terraform.json
```

```json
{"modules.v1":"/terraform/modules/v1/","providers.v1":"/terraform/providers/v1/"}
```

## Step 4: Publish a Module

Publishing needs two things: a deploy key for the module, which you create in Tapir, and an IAM role the
module repository's release workflow can assume to read that key.

### Create the IAM Role

Add the module repository to `terraform_modules`. Set `gh_org_name` if the repository is not in the
`infrahouse` organization.

```hcl
module "registry" {
  # ...
  gh_org_name       = "example"
  terraform_modules = ["terraform-aws-key"]
}
```

After `terraform apply`, `module.registry.registry_client_role_arns["terraform-aws-key"]` holds the role ARN.
The role can only read items from the `DeployKeys` table.

### Create a Deploy Key

In the Tapir UI, create a deploy key for the module, for example namespace `example`, name `key`, provider `aws`.
Tapir saves it in the `DeployKeys` table under the ID `example-key-aws`.

### Add a Release Workflow

[`ih-registry`](https://pypi.org/project/infrahouse-toolkit/) from infrahouse-toolkit reads the deploy key from
DynamoDB, zips the repository, and uploads it to Tapir. This workflow publishes every tag pushed to the module
repository:

```yaml
name: Publish module

on:  # yamllint disable-line rule:truthy
  push:
    tags:
      - "*"

permissions:
  id-token: write  # lets the job request a GitHub OIDC token
  contents: read

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: aws-actions/configure-aws-credentials@v5
        with:
          role-to-assume: arn:aws:iam::123456789012:role/ih-tf-terraform-aws-key-github
          aws-region: us-west-2  # the region where the registry runs

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

Push a tag such as `1.0.0` and the workflow publishes version `1.0.0` of `example/key/aws`.

## Step 5: Use the Module

```hcl
module "key" {
  source  = "registry.example.com/example/key/aws"
  version = "1.0.0"
}
```

`terraform init` discovers the registry, asks Tapir for the module, and downloads the archive from S3 through a
pre-signed URL.

## Next Steps

- [Configuration](configuration.md) — task counts, hostname, and the rest of the variables
- [Architecture](architecture.md) — how the pieces fit together
- [Security](security.md) — who can read, publish, and administer modules

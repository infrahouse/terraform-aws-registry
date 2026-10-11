# Configuration

## Inputs

| Name | Type | Default | Required |
|------|------|---------|:--------:|
| [`environment`](#environment) | `string` | n/a | yes |
| [`subnets_frontend`](#subnets_frontend) | `list(string)` | n/a | yes |
| [`subnets_backend`](#subnets_backend) | `list(string)` | n/a | yes |
| [`zone_id`](#zone_id) | `string` | n/a | yes |
| [`cognito_users`](#cognito_users) | `list(object)` | n/a | yes |
| [`replication_region`](#replication_region) | `string` | n/a | yes |
| [`registry_hostname`](#registry_hostname) | `string` | `"registry"` | no |
| [`service_name`](#service_name) | `string` | `"terraform-registry"` | no |
| [`task_min_count`](#task_min_count-and-task_max_count) | `number` | `2` | no |
| [`task_max_count`](#task_min_count-and-task_max_count) | `number` | `10` | no |
| [`on_demand_base_capacity`](#on_demand_base_capacity) | `number` | `1` | no |
| [`terraform_modules`](#terraform_modules) | `list(string)` | `[]` | no |
| [`gh_org_name`](#gh_org_name) | `string` | `"infrahouse"` | no |
| [`access_log_force_destroy`](#access_log_force_destroy) | `bool` | `false` | no |
| [`tags`](#tags) | `map(string)` | `{}` | no |

### `environment`

Environment name such as `production` or `development`. It goes to the `environment` tag of every resource the
module creates and is part of the CloudWatch log group name, `/ecs/<environment>/<service_name>`. There is no
default on purpose: you decide which environment a registry belongs to.

```hcl
environment = "production"
```

### `subnets_frontend`

Subnets for the internet-facing load balancer. They must be public subnets in at least two availability zones.
The module also uses the VPC of the first subnet to look up the internet gateway.

```hcl
subnets_frontend = module.network.subnet_public_ids
```

### `subnets_backend`

Subnets for the ECS container instances. Use private subnets with a route to a NAT gateway: the instances pull
the Tapir image from Docker Hub and call AWS APIs.

```hcl
subnets_backend = module.network.subnet_private_ids
```

### `zone_id`

ID of the Route 53 hosted zone where the module creates the registry's DNS record and validates the ACM
certificate. The zone must be in the same AWS account.

```hcl
zone_id = "Z1234567890ABC"
```

### `cognito_users`

People who can sign in to the Tapir web UI. For each entry the module creates a Cognito user with a random
temporary password and adds it to the `admin` group; Cognito emails the user the password.

```hcl
cognito_users = [
  {
    email     = "jane@example.com"
    full_name = "Jane Admin"
  },
  {
    email     = "john@example.com"
    full_name = "John Admin"
  },
]
```

Removing an entry deletes the user. Every user is an admin; the module has no read-only role, and reading
modules through the registry API needs no account at all.

### `replication_region`

Region for the cross-region replica of the bucket with module archives. Archives are the only copy of what was
published, so the module replicates each new one to a second bucket in this region. Replication also turns on
versioning of the archive bucket. The region must differ from the one the registry runs in.

```hcl
replication_region = "us-east-1"
```

!!! note
    S3 replicates objects written after replication is turned on. When you upgrade an existing registry, the
    archives published before the upgrade are not copied — see [Upgrading](upgrading.md).

### `registry_hostname`

The host part of the registry's DNS name. Combined with the hosted zone it gives the registry URL:
`registry_hostname = "terraform"` in zone `example.com` publishes the registry at `https://terraform.example.com`.

!!! warning
    Module sources contain the registry hostname, for example `registry.example.com/example/key/aws`. Changing
    the hostname breaks every configuration that uses the old one.

### `service_name`

Name of the ECS service. It also prefixes the Cognito user pool, app client, and hosted UI domain, and is part of
the log group name. The Cognito domain prefix, `<service_name>-<region>`, must be unique across all AWS accounts
in the region; change `service_name` if the default is taken.

```hcl
service_name = "terraform-registry-2"
```

### `task_min_count` and `task_max_count`

Bounds for the number of Tapir tasks. The ECS service scales between them on average CPU utilization. Keep
`task_min_count` at 2 or more so a single failed task does not take the registry down.

```hcl
task_min_count = 2
task_max_count = 4
```

### `on_demand_base_capacity`

How many container instances in the Auto Scaling group must be on-demand. Every instance above this number is a
spot instance.

```hcl
on_demand_base_capacity = 2
```

### `terraform_modules`

GitHub repositories that publish modules to the registry. For each one the module creates an IAM role,
`ih-tf-<repo>-github`, that a GitHub Actions workflow in `<gh_org_name>/<repo>` can assume through OIDC. The role
may only read items from the `DeployKeys` table.

```hcl
terraform_modules = [
  "terraform-aws-key",
  "terraform-aws-secret",
]
```

The account needs a GitHub OIDC identity provider before you add the first repository. See
[Getting Started](getting-started.md#step-4-publish-a-module) for the whole publishing setup.

### `gh_org_name`

GitHub organization that owns the repositories in `terraform_modules`.

```hcl
gh_org_name = "example"
```

### `access_log_force_destroy`

Set to `true` to let `terraform destroy` delete the load balancer's access log bucket even when it holds logs.
Useful for test environments; leave it `false` in production.

### `tags`

!!! warning
    Version 0.4.0 accepts this variable but does not apply it to any resource. Use the AWS provider's
    `default_tags` to tag the registry's resources until it does.

## Outputs

| Name | Description |
|------|-------------|
| `registry_url` | HTTPS URL of the registry, for example `https://registry.example.com` |
| `registry_client_role_arns` | Map of repository name to the ARN of its registry client role |
| `registry_client_role_names` | Map of repository name to the name of its registry client role |
| `bucket_name` | Name of the S3 bucket with module archives |
| `bucket_arn` | ARN of the S3 bucket with module archives |

Pass a `registry_client_role_arns` value to `aws-actions/configure-aws-credentials` as `role-to-assume`:

```hcl
output "key_module_publisher_role" {
  value = module.registry.registry_client_role_arns["terraform-aws-key"]
}
```

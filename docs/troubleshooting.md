# Troubleshooting

The commands below use the default `service_name`, `terraform-registry`. Replace it if you set your own.

## Deployment

### Cognito Domain Already Exists

```text
Error: creating Cognito User Pool Domain (terraform-registry-us-west-2): ... InvalidParameterException:
Domain already associated with another user pool.
```

The hosted UI domain prefix is `<service_name>-<region>`, and Cognito domain prefixes are unique across all AWS
accounts in a region. Another user pool — yours or someone else's — already has it. Set a different
`service_name`:

```hcl
service_name = "example-terraform-registry"
```

### DynamoDB Table Already Exists

```text
Error: creating Amazon DynamoDB Table (DeployKeys): ... ResourceInUseException: Table already exists: DeployKeys
```

The table names are fixed, so the account and region can hold only one registry. Deploy the second registry in
another region or account, or remove the old tables if nothing uses them any more.

### No Internet Gateway Found

```text
Error: no matching EC2 Internet Gateway found
  with module.registry.data.aws_internet_gateway.main
```

The module looks up the internet gateway attached to the VPC of the first subnet in `subnets_frontend`. Check that
the subnets are the public subnets of a VPC with an internet gateway.

### The Plan Changes the Launch Template When Nothing Else Changed

The container instances use the most recent Amazon ECS-optimized AMI. When AWS publishes a new one, the next plan
updates the launch template, and the apply replaces the instances one by one. This is expected and keeps the
instances patched.

## Signing In

### The Invitation Email Did Not Arrive

Cognito sends invitations from `no-reply@verificationemail.com`; check the spam folder first. The module uses the
built-in Cognito email sender, which has a low daily sending quota.

A temporary password expires seven days after Cognito creates the user. To send a new invitation:

```bash
POOL_ID=$(aws cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='terraform-registry-user-pool'].Id" --output text)

aws cognito-idp admin-create-user \
  --user-pool-id "$POOL_ID" \
  --username jane@example.com \
  --message-action RESEND
```

### Cognito Shows `redirect_mismatch`

The browser came in through a hostname other than the registry URL — the load balancer's DNS name, for example.
The app client accepts only the registry URL as a callback. Open the URL from the `registry_url` output.

### Signed In, but the UI Shows No Admin Pages

Only members of the `admin` group get the admin UI. Users the module created are members; users added to the pool
by hand are not. Add them to `cognito_users` instead.

## The Registry Is Down

### The Load Balancer Returns 502 or 503

The ALB has no healthy Tapir task. Look at the ECS service events and the container logs:

```bash
aws ecs describe-services \
  --cluster terraform-registry \
  --services terraform-registry \
  --query "services[0].events[:10].message"

aws logs tail /ecs/<environment>/terraform-registry --since 1h
```

For tasks that stopped before they could log anything, the stop reason tells why:

```bash
aws ecs list-tasks --cluster terraform-registry --desired-status STOPPED
aws ecs describe-tasks --cluster terraform-registry --tasks <task arn> --query "tasks[0].stoppedReason"
```

The most common cause is private subnets without a route to a NAT gateway: the instances then cannot pull the
Tapir image, read the Cognito client secret, or reach Cognito, DynamoDB, and S3.

## Publishing

### `Not authorized to perform sts:AssumeRoleWithWebIdentity`

The workflow could not assume the registry client role. Check that the job has `id-token: write`, that the
repository is in `terraform_modules`, and that `gh_org_name` matches the repository's organization. The
[terraform-aws-github-role troubleshooting guide](https://infrahouse.github.io/terraform-aws-github-role/troubleshooting/)
goes through the remaining causes.

### `ih-registry upload` Fails with `KeyError: 'Item'`

`ih-registry` found no deploy key for the module. It looks up the ID `<namespace>-<name>-<provider>` in the
`DeployKeys` table. Check that:

- a deploy key for exactly this module exists in the Tapir UI
- `--module-name` (or the namespace, name, and provider `ih-registry` derives from the directory name) matches it
- the workflow's `aws-region` is the region where the registry runs

### `ResourceNotFoundException` When Reading the Deploy Key

The `DeployKeys` table does not exist in the region the workflow uses. Set `aws-region` in
`aws-actions/configure-aws-credentials` to the registry's region.

### `ih-registry upload` Gets an HTTP Error from the Registry

The deploy key was read, but Tapir rejected the upload. Usually the key belongs to a different module than the one
in the upload URL. Create a deploy key for the exact `<namespace>/<name>/<provider>` you upload.

## Using Modules

### `terraform init` Cannot Find the Module

```text
Error: Module not found
```

Ask the registry what it has:

```bash
curl https://registry.example.com/.well-known/terraform.json
curl https://registry.example.com/terraform/modules/v1/example/key/aws/versions
```

If the first command fails, the registry is not reachable or not healthy — see
[The Registry Is Down](#the-registry-is-down). If the second returns no versions, nothing was published under
that namespace, name, and provider; compare the module source with the `--module-name` of the upload.

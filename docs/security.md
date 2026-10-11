# Security

## Who Can Do What

| Action | Who | How it is enforced |
|--------|-----|--------------------|
| Download modules, list versions | Anyone who can reach the registry URL | Nothing — reads are anonymous |
| Publish a module version | Anyone holding that module's deploy key | Tapir checks the `x-api-key` header |
| Read a deploy key | Registry client roles | IAM: `dynamodb:GetItem` on the `DeployKeys` table |
| Sign in to the web UI, create deploy keys | Users in `cognito_users` | Cognito sign-in and the `admin` group |

### Modules Are Readable by Anyone

The load balancer is internet-facing, and Tapir serves module versions and download links without
authentication. Treat every module you publish as public: never put credentials, internal hostnames you need
to keep secret, or proprietary code you cannot disclose into a module archive. `ih-registry upload` zips the
whole repository directory, so check what the checkout contains, too.

### Deploy Keys Are Shared Through One Table

Every registry client role can read the whole `DeployKeys` table, not only the key of its own module. A workflow
that can assume one module's role can therefore read every module's deploy key and publish a version of any
module. Limit who can push tags to the module repositories, and protect release workflows with
[GitHub environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)
and required reviewers.

### Every Web UI User Is an Admin

All users in `cognito_users` join the `admin` group; the module has no read-only role. The password policy
requires at least 21 characters with upper- and lower-case letters, numbers, and symbols. The module does not
turn on MFA.

## Secrets

- **Cognito app client secret.** Stored in Secrets Manager through
  [infrahouse/secret/aws](https://github.com/infrahouse/terraform-aws-secret). Only the ECS task execution role
  can read it; ECS injects it into the container as `AUTH_CLIENT_SECRET`.
- **Temporary passwords.** The module generates each user's temporary password with `random_password`, so the
  password is in the Terraform state. It stops working once the user sets a permanent password, but until then
  anyone who can read the state can sign in as that user. Keep the state in an encrypted bucket with restricted
  access.
- **Deploy keys.** Tapir keeps them in the `DeployKeys` DynamoDB table, readable by the Tapir task role and the
  registry client roles.

## Data Protection

- **In transit:** the load balancer terminates HTTPS with an ACM certificate. Module downloads use pre-signed
  HTTPS URLs to S3.
- **At rest:** the S3 bucket is encrypted, versioned, and blocks public access. DynamoDB encrypts the tables by
  default.
- **Recovery:** point-in-time recovery is on for all DynamoDB tables. S3 versioning keeps overwritten or
  deleted archives, and cross-region replication keeps a copy of every archive in `replication_region`.

## IAM

- **Task role** (`registry-node-*`): `dynamodb:*` on the four registry tables and `s3:*` on the registry bucket
  and its objects. Its trust policy allows only `ecs-tasks.amazonaws.com` from the same account.
- **Registry client roles** (`ih-tf-<repo>-github`): trust GitHub Actions workflows from `<gh_org_name>/<repo>`
  through OIDC and allow only `dynamodb:GetItem` on the `DeployKeys` table. See
  [terraform-aws-github-role](https://infrahouse.github.io/terraform-aws-github-role/security/) for how the trust
  policy works.

## Logging

Tapir's container logs go to the CloudWatch log group `/ecs/<environment>/<service_name>`, kept 365 days.
Container Insights is on for the ECS cluster. The load balancer writes access logs to an S3 bucket.

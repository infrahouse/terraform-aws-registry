# Upgrading

## To 0.6.0

### New Required Variable: `replication_region`

The module archive bucket now replicates to a second region. Version 0.9.0 of
[infrahouse/s3-bucket/aws](https://github.com/infrahouse/terraform-aws-s3-bucket) requires cross-region replication,
and the archives are the only copy of what was published, so the module turns it on rather than opting out.

Pick a region other than the one the registry runs in:

```hcl
module "registry" {
  source  = "registry.infrahouse.com/infrahouse/registry/aws"
  version = "0.6.0"

  # ...
  replication_region = "us-east-1"
}
```

The module also needs Terraform `~> 1.9` now, because the bucket module does.

### What the Plan Shows

`terraform plan` adds resources and changes nothing destructively:

- a replica bucket `terraform-registry--replica*` in `replication_region`, with its encryption, versioning,
  public access block, and bucket policy
- an IAM role and policy that S3 uses to replicate
- versioning and a replication configuration on the existing archive bucket
- in-place updates to the existing bucket's tags, and to its policy, which gains a statement denying
  KMS-encrypted uploads (Tapir uploads use the bucket's default SSE-S3 encryption)

The existing bucket, `module.terraform-registry-bucket.aws_s3_bucket.this`, must not be replaced. If the plan says
it will be, stop and open an issue.

### Copy the Archives Published Before the Upgrade

S3 replicates only objects written after replication is turned on. To copy the archives that already exist, either
run an [S3 Batch Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-batch-replication-batch.html)
job for the bucket, or copy them with the AWS CLI:

```bash
SOURCE=$(terraform output -raw bucket_name)   # assumes you expose module.registry.bucket_name
REPLICA=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, 'terraform-registry--replica')].Name" \
  --output text)

aws s3 sync "s3://$SOURCE" "s3://$REPLICA"
```

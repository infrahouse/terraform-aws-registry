module "terraform-registry-bucket" {
  source  = "registry.infrahouse.com/infrahouse/s3-bucket/aws"
  version = "0.9.0"

  bucket_prefix = "terraform-registry-"

  # Module archives are the only copy of what was published, so replicate them to a second region.
  # Replication also turns on versioning of the bucket.
  replication_region = var.replication_region

  tags = local.default_module_tags
}

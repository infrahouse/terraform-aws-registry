module "terraform-registry-bucket" {
  source  = "registry.infrahouse.com/infrahouse/s3-bucket/aws"
  version = "0.3.1"

  bucket_prefix = "terraform-registry-"
  tags          = local.default_module_tags
}

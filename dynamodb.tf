resource "aws_dynamodb_table" "registry_tables" {
  for_each = toset(local.dynamodb_tables)

  name         = each.key
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # DeployKeys holds every module's deploy keys and Modules indexes the registry: keep them recoverable.
  point_in_time_recovery {
    enabled = true
  }

  tags = local.default_module_tags
}

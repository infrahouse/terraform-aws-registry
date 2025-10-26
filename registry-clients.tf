### IAM roles that can upload to the registry
module "registry-client-roles" {
  source      = "registry.infrahouse.com/infrahouse/github-role/aws"
  version     = "1.4.0"
  for_each    = toset(var.terraform_modules)
  gh_org_name = var.gh_org_name
  repo_name   = each.key
}


resource "aws_iam_role_policy_attachment" "registry-client" {
  for_each   = toset(var.terraform_modules)
  policy_arn = aws_iam_policy.registry-client.arn
  role       = module.registry-client-roles[each.key].github_role_name
}

resource "aws_iam_policy" "registry-client" {
  name_prefix = "registry-client"
  policy      = data.aws_iam_policy_document.registry-client-permissions.json
  tags        = local.default_module_tags
}


data "aws_iam_policy_document" "registry-client-permissions" {
  statement {
    actions = [
      "dynamodb:GetItem"
    ]
    resources = [
      aws_dynamodb_table.registry_tables["DeployKeys"].arn
    ]
  }
}

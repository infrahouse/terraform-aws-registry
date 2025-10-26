# --- Cognito User Pool ---
resource "aws_cognito_user_pool" "this" {
  name = "${local.service_name}-user-pool"

  # Use email as username
  username_attributes = ["email"]

  # Basic password policy (tighten if needed)
  password_policy {
    minimum_length    = local.minimum_password_length
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]

  # Keep it simple: built-in Cognito email delivery for now
  # (Switch to SES later if you want branded emails)
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Optional: add a standard "name" attribute
  schema {
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    name                     = "name"
    required                 = false
    string_attribute_constraints {
      max_length = "2048"
      min_length = "0"
    }
  }
  tags = local.default_module_tags
}

# --- Hosted UI Domain ---
# Uses a Cognito-managed domain like https://<prefix>.auth.<region>.amazoncognito.com
resource "aws_cognito_user_pool_domain" "this" {
  domain       = "${local.service_name}-${data.aws_region.current.name}"
  user_pool_id = aws_cognito_user_pool.this.id
}

# --- App Client (OIDC / OAuth2) ---
# Authorization Code + PKCE, with optional client secret.
resource "aws_cognito_user_pool_client" "this" {
  name            = "${local.service_name}-app"
  user_pool_id    = aws_cognito_user_pool.this.id
  generate_secret = true

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes = [
    "openid",
    "email",
    "profile"
  ]

  supported_identity_providers = ["COGNITO"]


  callback_urls = [
    local.registry_url,
    "${local.registry_url}/",
  ]
  logout_urls = [
    local.registry_url,
  ]

  # Keep tokens reasonably short; Tapir will mostly care about ID token claims.
  id_token_validity      = 60
  access_token_validity  = 60
  refresh_token_validity = 30
  token_validity_units {
    id_token      = "minutes"
    access_token  = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"

  # Enable PKCE (Cognito enforces it for public clients automatically).
  enable_token_revocation                       = true
  enable_propagate_additional_user_context_data = true

}

resource "random_password" "users" {
  for_each = { for user in var.cognito_users : user.email => user }
  length   = local.minimum_password_length + 1
}

resource "aws_cognito_user" "users" {
  for_each = { for user in var.cognito_users : user.email => user }

  user_pool_id = aws_cognito_user_pool.this.id
  username     = each.value.email

  attributes = {
    email          = each.value.email
    email_verified = "true"
    name           = each.value.full_name
  }
  temporary_password = random_password.users[each.key].result
}

# Add your user (by username/email) to the admin group
resource "aws_cognito_user_in_group" "admin" {
  for_each     = { for user in var.cognito_users : user.email => user }
  user_pool_id = aws_cognito_user_pool.this.id
  group_name   = aws_cognito_user_group.admin.name
  username     = aws_cognito_user.users[each.key].username
}

# Create "admin" group in the same user pool
resource "aws_cognito_user_group" "admin" {
  user_pool_id = aws_cognito_user_pool.this.id
  name         = "admin"
  description  = "Administrators of Tapir registry"
  precedence   = 1 # lower = higher priority when multiple groups
}

# Cognito User Pool
resource "aws_cognito_user_pool" "resume_user_pool" {
  name = "ResumeRxUserPool"

  # Allow users to sign up themselves
  admin_create_user_config {
    allow_admin_create_user_only = false  # Enables self-service sign-up
  }

  # Password policy
  password_policy {
    minimum_length    = 10
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
    temporary_password_validity_days = 7
  }

  # Auto-verify email and use it for recovery
  auto_verified_attributes = ["email"]
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Username config (email as username)
  username_attributes = ["email"]  # Users log in with email
  alias_attributes    = ["email"]  # Email is the alias for sign-in

  # MFA (optional, off for now)
  mfa_configuration = "OFF"

  # Email configuration for verification and recovery
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
}

# Cognito App Client
resource "aws_cognito_user_pool_client" "resume_app_client" {
  name                = "ResumeRxAppClient"
  user_pool_id        = aws_cognito_user_pool.resume_user_pool.id
  generate_secret     = false
  callback_urls       = ["http://${aws_s3_bucket_website_configuration.frontend_bucket_website.website_endpoint}/"]
  logout_urls         = ["http://${aws_s3_bucket_website_configuration.frontend_bucket_website.website_endpoint}/"]
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  supported_identity_providers = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "resume_domain" {
  domain       = "resumerx-auth-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.resume_user_pool.id
}

# Outputs
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.resume_user_pool.id
}

output "cognito_app_client_id" {
  value = aws_cognito_user_pool_client.resume_app_client.id
}

output "cognito_domain" {
  value = "https://${aws_cognito_user_pool_domain.resume_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}
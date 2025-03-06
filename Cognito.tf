resource "aws_cognito_user_pool" "resume_user_pool" {
  name = "ResumeRxUserPool"
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  password_policy {
    minimum_length    = 10
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
    temporary_password_validity_days = 7
  }
  auto_verified_attributes = ["email"]
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
  username_attributes = ["email"]
  mfa_configuration = "OFF"
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }
}

resource "aws_cognito_user_pool_client" "resume_app_client" {
  name                = "ResumeRxAppClient"
  user_pool_id        = aws_cognito_user_pool.resume_user_pool.id
  generate_secret     = false
  callback_urls       = ["https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"]
  logout_urls         = ["https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"]
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  supported_identity_providers = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = true
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
}

resource "aws_cognito_user_pool_domain" "resume_domain" {
  domain       = "resumerx-auth-${random_string.suffix.result}"
  user_pool_id = aws_cognito_user_pool.resume_user_pool.id
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.resume_user_pool.id
}

output "cognito_app_client_id" {
  value = aws_cognito_user_pool_client.resume_app_client.id
}

output "cognito_domain" {
  value = "https://${aws_cognito_user_pool_domain.resume_domain.domain}.auth.${var.aws_region}.amazoncognito.com"
}

output "cloudfront_callback_url" {
  value = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}/"
}
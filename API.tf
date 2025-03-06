resource "aws_apigatewayv2_api" "resume_api" {
  name          = "ResumeRxAPIv2"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"]
    allow_methods = ["OPTIONS", "POST"]
    allow_headers = ["Content-Type", "Authorization"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.resume_api.id
  name        = "prod"
  auto_deploy = true
}

# Save Profile Route with Authorizer
resource "aws_apigatewayv2_route" "save_profile" {
  api_id             = aws_apigatewayv2_api.resume_api.id
  route_key          = "POST /save-profile"
  target             = "integrations/${aws_apigatewayv2_integration.save_profile.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_integration" "save_profile" {
  api_id                 = aws_apigatewayv2_api.resume_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.save_profile_lambda.invoke_arn
  payload_format_version = "2.0"
}

# Generate Resume Route with Authorizer
resource "aws_apigatewayv2_route" "generate_resume" {
  api_id             = aws_apigatewayv2_api.resume_api.id
  route_key          = "POST /generate-resume"
  target             = "integrations/${aws_apigatewayv2_integration.generate_resume.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_integration" "generate_resume" {
  api_id                 = aws_apigatewayv2_api.resume_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.generate_resume_lambda.invoke_arn
  payload_format_version = "2.0"
}

# Cognito Authorizer
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.resume_api.id
  name             = "CognitoAuthorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.resume_app_client.id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.resume_user_pool.id}"
  }
}

# Lambda Permissions
resource "aws_lambda_permission" "api_gateway_save_profile" {
  statement_id  = "AllowAPIGatewayInvokeSaveProfile"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.save_profile_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.resume_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gateway_generate_resume" {
  statement_id  = "AllowAPIGatewayInvokeGenerateResume"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_resume_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.resume_api.execution_arn}/*/*"
}

# Outputs
output "save_profile_endpoint" {
  value = "${aws_apigatewayv2_api.resume_api.api_endpoint}/prod/save-profile"
}

output "generate_resume_endpoint" {
  value = "${aws_apigatewayv2_api.resume_api.api_endpoint}/prod/generate-resume"
}
# API Gateway REST API
resource "aws_api_gateway_rest_api" "resume_api" {
  name = "ResumeRxAPI"
}

# Resource for /save-profile
resource "aws_api_gateway_resource" "save_profile_resource" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  parent_id   = aws_api_gateway_rest_api.resume_api.root_resource_id
  path_part   = "save-profile"
}

# POST method for /save-profile
resource "aws_api_gateway_method" "save_profile_method" {
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  resource_id   = aws_api_gateway_resource.save_profile_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration with SaveProfileLambda
resource "aws_api_gateway_integration" "save_profile_integration" {
  rest_api_id             = aws_api_gateway_rest_api.resume_api.id
  resource_id             = aws_api_gateway_resource.save_profile_resource.id
  http_method             = aws_api_gateway_method.save_profile_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.save_profile_lambda.invoke_arn
}

# Resource for /generate-resume
resource "aws_api_gateway_resource" "generate_resume_resource" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  parent_id   = aws_api_gateway_rest_api.resume_api.root_resource_id
  path_part   = "generate-resume"
}

# POST method for /generate-resume
resource "aws_api_gateway_method" "generate_resume_method" {
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  resource_id   = aws_api_gateway_resource.generate_resume_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integration with GenerateResumeLambda
resource "aws_api_gateway_integration" "generate_resume_integration" {
  rest_api_id             = aws_api_gateway_rest_api.resume_api.id
  resource_id             = aws_api_gateway_resource.generate_resume_resource.id
  http_method             = aws_api_gateway_method.generate_resume_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.generate_resume_lambda.invoke_arn
}

# Permission for API Gateway to invoke SaveProfileLambda
resource "aws_lambda_permission" "save_profile_api_permission" {
  statement_id  = "AllowAPIGatewayInvokeSaveProfile"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.save_profile_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume_api.execution_arn}/*/*"
}

# Permission for API Gateway to invoke GenerateResumeLambda
resource "aws_lambda_permission" "generate_resume_api_permission" {
  statement_id  = "AllowAPIGatewayInvokeGenerateResume"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.generate_resume_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.resume_api.execution_arn}/*/*"
}

# API deployment
resource "aws_api_gateway_deployment" "resume_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.resume_api.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.save_profile_resource.id,
      aws_api_gateway_method.save_profile_method.id,
      aws_api_gateway_integration.save_profile_integration.id,
      aws_api_gateway_resource.generate_resume_resource.id,
      aws_api_gateway_method.generate_resume_method.id,
      aws_api_gateway_integration.generate_resume_integration.id
    ]))
  }

  depends_on = [
    aws_api_gateway_integration.save_profile_integration,
    aws_api_gateway_integration.generate_resume_integration
  ]
}

# API stage
resource "aws_api_gateway_stage" "resume_api_stage" {
  rest_api_id   = aws_api_gateway_rest_api.resume_api.id
  deployment_id = aws_api_gateway_deployment.resume_api_deployment.id
  stage_name    = "prod"
}

# Output the endpoints
output "save_profile_endpoint" {
  value = "${aws_api_gateway_stage.resume_api_stage.invoke_url}/save-profile"
}

output "generate_resume_endpoint" {
  value = "${aws_api_gateway_stage.resume_api_stage.invoke_url}/generate-resume"
}
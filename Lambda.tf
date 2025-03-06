resource "aws_lambda_function" "save_profile_lambda" {
  filename      = "save_profile_lambda.zip"
  function_name = "SaveProfileLambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {
      FRONTEND_DOMAIN = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
    }
  }
}

resource "aws_lambda_function" "generate_resume_lambda" {
  filename      = "generate_resume_lambda.zip"
  function_name = "GenerateResumeLambda"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {
      FRONTEND_DOMAIN = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
    }
  }
}

# Assuming this exists in your Lambda.tf or another file
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "s3:PutObject",
          "comprehend:DetectEntities",
          "comprehend:DetectKeyPhrases"
        ]
        Resource = [
          aws_dynamodb_table.user_profiles.arn,
          "arn:aws:s3:::resumerx-resumes-5y3lp26l/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "logs:*"
        Resource = "*"
      }
    ]
  })
}
# IAM role for Lambda (shared by both functions)
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Policy for DynamoDB and S3 access (Comprehend moved to Comprehend.tf)
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:PutItem", "dynamodb:GetItem"]
        Resource = aws_dynamodb_table.user_profiles.arn
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.resume_bucket.arn}/*"
      }
    ]
  })
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function for save-profile
resource "aws_lambda_function" "save_profile_lambda" {
  function_name = "SaveProfileLambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = "save_profile_lambda.zip"
  source_code_hash = filebase64sha256("save_profile_lambda.zip")
}

# Lambda function for generate-resume
resource "aws_lambda_function" "generate_resume_lambda" {
  function_name = "GenerateResumeLambda"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = "generate_resume_lambda.zip"
  source_code_hash = filebase64sha256("generate_resume_lambda.zip")
}
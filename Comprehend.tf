# Optional: Dedicated IAM policy for Comprehend access (if you want to separate it from Lambda.tf)
resource "aws_iam_policy" "comprehend_policy" {
  name        = "ResumeRxComprehendPolicy"
  description = "Policy for accessing Amazon Comprehend in ResumeRx"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "comprehend:DetectEntities",
          "comprehend:DetectKeyPhrases"
        ]
        Resource = "*"  # Comprehend doesn't use resource-level permissions
      }
    ]
  })
}

# Attach the Comprehend policy to the Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_comprehend_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.comprehend_policy.arn
}
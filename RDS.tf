# DynamoDB table for user profiles
resource "aws_dynamodb_table" "user_profiles" {
  name           = "UserProfiles"
  billing_mode   = "PAY_PER_REQUEST"  # Serverless, no capacity provisioning
  hash_key       = "userId"

  attribute {
    name = "userId"
    type = "S"  # String type for userId
  }

  # Optional: Add TTL for auto-expiring old data
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Tags for organization
  tags = {
    Name        = "ResumeRxUserProfiles"
    Environment = "prod"
  }
}
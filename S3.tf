# Random suffix to ensure unique bucket names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Frontend S3 bucket (static website hosting)
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "resumerx-frontend-${random_string.suffix.result}"
}

resource "aws_s3_bucket_ownership_controls" "frontend_bucket_ownership" {
  bucket = aws_s3_bucket.frontend_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_bucket_public_access" {
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "frontend_bucket_acl" {
  bucket = aws_s3_bucket.frontend_bucket.id
  acl    = "public-read"
  depends_on = [
    aws_s3_bucket_ownership_controls.frontend_bucket_ownership,
    aws_s3_bucket_public_access_block.frontend_bucket_public_access
  ]
}

resource "aws_s3_bucket_website_configuration" "frontend_bucket_website" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Resume S3 bucket (private storage for PDFs)
resource "aws_s3_bucket" "resume_bucket" {
  bucket = "resumerx-resumes-${random_string.suffix.result}"
}

resource "aws_s3_bucket_ownership_controls" "resume_bucket_ownership" {
  bucket = aws_s3_bucket.resume_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "resume_bucket_public_access" {
  bucket                  = aws_s3_bucket.resume_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "resume_bucket_acl" {
  bucket = aws_s3_bucket.resume_bucket.id
  acl    = "private"
  depends_on = [aws_s3_bucket_ownership_controls.resume_bucket_ownership]
}

# Outputs for bucket names and URLs
output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend_bucket.bucket
}

output "frontend_website_url" {
  value = aws_s3_bucket_website_configuration.frontend_bucket_website.website_endpoint
}

output "resume_bucket_name" {
  value = aws_s3_bucket.resume_bucket.bucket
}
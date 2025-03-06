# Random suffix (fixed to match existing buckets)
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  keepers = { id = "5y3lp26l" }  # Lock to existing suffix
}

# Frontend S3 bucket (static website hosting)
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "resumerx-frontend-5y3lp26l"
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

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "index.html"
  source       = "~/Desktop/Class 6 work/templates1/index.html"
  acl          = "public-read"
  content_type = "text/html"
  depends_on   = [aws_s3_bucket_acl.frontend_bucket_acl]
}

# CloudFront distribution for frontend
resource "aws_cloudfront_distribution" "frontend_distribution" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.frontend_bucket_website.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.frontend_bucket.bucket}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend_bucket.bucket}"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Resume S3 bucket (private storage for PDFs)
resource "aws_s3_bucket" "resume_bucket" {
  bucket = "resumerx-resumes-5y3lp26l"
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

# CloudFront OAI for resume bucket
resource "aws_cloudfront_origin_access_identity" "resume_oai" {
  comment = "OAI for resumerx-resumes-5y3lp26l"
}

# CloudFront distribution for resumes
resource "aws_cloudfront_distribution" "resume_distribution" {
  origin {
    domain_name = aws_s3_bucket.resume_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.resume_bucket.bucket}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.resume_oai.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = ""

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.resume_bucket.bucket}"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Resume bucket policy
resource "aws_s3_bucket_policy" "resume_bucket_policy" {
  bucket = aws_s3_bucket.resume_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.resume_oai.id}" }
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::resumerx-resumes-5y3lp26l/*"
      },
      {
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.lambda_exec_role.arn }
        Action    = ["s3:PutObject", "s3:GetObject"]
        Resource  = "arn:aws:s3:::resumerx-resumes-5y3lp26l/*"
      }
    ]
  })
}

# Outputs
output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend_bucket.bucket
}

output "frontend_website_url" {
  value = "https://${aws_cloudfront_distribution.frontend_distribution.domain_name}"
}

output "resume_bucket_name" {
  value = aws_s3_bucket.resume_bucket.bucket
}

output "resume_cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.resume_distribution.domain_name}"
}

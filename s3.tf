# 2.2 Create a private S3 bucket with a randomly generated bucket name depending on the environment
resource "random_id" "random_id" {
  byte_length = 4
}

resource "aws_kms_key" "sse_kms_key" {
  description         = "KMS key for S3 server-side encryption"
  enable_key_rotation = true
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = "${terraform.workspace}-bucket-${random_id.random_id.hex}"
  acl    = "private"

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = aws_kms_key.sse_kms_key.arn
          sse_algorithm     = "aws:kms"
        }
      }
    }

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_configuration" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    id     = "lifecycle_configuration_rule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    filter {
      prefix = ""
    }
  }
}

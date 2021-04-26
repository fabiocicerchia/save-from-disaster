# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {}

# IAM
resource "aws_iam_user" "backup" {
  name = "backup"
}
resource "aws_iam_user_policy" "s3_backup_only" {
  name = "test"
  user = aws_iam_user.backup.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:PutObject", "s3:ListBucket"]
        Effect = "Allow"
        Resource = "arn:aws:s3:::*/*"
      }
    ]
  })
}

# S3 Bucket
resource "aws_s3_bucket" "db_backup" {
  bucket = "${var.namespace}-db-backup"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    id      = "hourly"
    enabled = true
    prefix = "hourly/"
    abort_incomplete_multipart_upload_days = 1
    expiration {
      days = 1
      expired_object_delete_marker = true
    }
    noncurrent_version_expiration {
      days = 1
    }
  }

  lifecycle_rule {
    id      = "daily"
    enabled = true
    prefix = "daily/"
    abort_incomplete_multipart_upload_days = 1
    expiration {
      days = 7
      expired_object_delete_marker = true
    }
    noncurrent_version_expiration {
      days = 7
    }
  }

  lifecycle_rule {
    id      = "weekly"
    enabled = true
    prefix = "weekly/"
    abort_incomplete_multipart_upload_days = 1
    expiration {
      days = 31
      expired_object_delete_marker = true
    }
    noncurrent_version_expiration {
      days = 31
    }
  }

  lifecycle_rule {
    id      = "monthly"
    enabled = true
    prefix = "monthly/"
    abort_incomplete_multipart_upload_days = 1
    expiration {
      days = 90
      expired_object_delete_marker = true
    }
    noncurrent_version_expiration {
      days = 90
    }
  }
}
resource "aws_s3_bucket_policy" "db_backup" {
  bucket = aws_s3_bucket.db_backup.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "Policy1"
    Statement = [
      {
        Sid    = "Stmt1"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/backup"
        },
        Action   = "s3:ListBucket"
        Resource = "${aws_s3_bucket.db_backup.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "storage" {
  bucket = "${var.namespace}-storage"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}
resource "aws_s3_bucket_policy" "storage" {
  bucket = aws_s3_bucket.storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "Policy1"
    Statement = [
      {
        Sid    = "Stmt1"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/backup"
        },
        Action   = "s3:ListBucket"
        Resource = "${aws_s3_bucket.storage.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket" "website_static_example_com" {
  bucket = "${var.namespace}-website-static-example.com"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}
resource "aws_s3_bucket_policy" "website_static_example_com" {
  bucket = aws_s3_bucket.website_static_example_com.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "Policy1"
    Statement = [
      {
        Sid    = "Stmt1"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/backup"
        },
        Action   = "s3:ListBucket"
        Resource = "${aws_s3_bucket.website_static_example_com.arn}/*"
      }
    ]
  })
}

provider "aws" {
  region = "us-east-1"
}

# Create S3 Bucket for Terraform State:
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "terraform-state-prod-1234567890"
  force_destroy = false

  tags = {
    Name        = "TerraformStateBucket"
    Environment = "Production"
  }
}

# Enable Versioning on S3:
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Apply Bucket Ownership Controls
resource "aws_s3_bucket_ownership_controls" "ownership" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Apply Bucket Policy (Restrict access) to ensure secure access to the Terraform state file by 
#Forcing Secure Transport (HTTPS Only)
#Preventing Unauthorized Access
#"Principal": "*"
#This applies to all users (including IAM users, roles, and the public).

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::terraform-state-prod-1234567890",
        "arn:aws:s3:::terraform-state-prod-1234567890/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

# Create DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "TerraformLocksTable"
    Environment = "Production"
  }
}

# Create IAM Role for Terraform State Access
resource "aws_iam_role" "terraform_state_role" {
  name = "TerraformStateAccessRole"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::989557614958:user/Sunit"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Create IAM Policy for S3 and DynamoDB Access
resource "aws_iam_policy" "terraform_state_policy" {
  name        = "TerraformStateAccessPolicy"
  description = "Policy for Terraform to access S3 and DynamoDB"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::terraform-state-prod-1234567890"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::terraform-state-prod-1234567890/*"
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:DeleteItem"],
      "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-state-locks"
    },
    { 
      "Effect": "Allow",
      "Action": ["iam:GetRole", "iam:GetPolicy"],
      "Resource": "*"
    }
  ]
}
POLICY
}

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.terraform_state_role.name
  policy_arn = aws_iam_policy.terraform_state_policy.arn
}

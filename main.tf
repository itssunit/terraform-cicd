
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name = var.name
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_s3_bucket" "terraform-example" {
#   bucket = var.s3_bucket_name
# }

# resource "aws_s3_bucket_versioning" "versioning_example" {
#   bucket = aws_s3_bucket.terraform-example.bucket
#   versioning_configuration {
#     status = "Enabled"
#   }
#   depends_on = [ aws_s3_bucket.terraform-example ]
# }

# resource "aws_s3_bucket_policy" "secure_policy" {
#   bucket = aws_s3_bucket.terraform-example.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::989557614958:user/Sunit"
#         }
#         Action = ["s3:GetObject", "s3:PutObject"]
#         Resource = "${aws_s3_bucket.terraform-example.arn}/*"
#       }
#     ]
#   })
# }


resource "aws_dynamodb_table" "state-lock-table" {
  hash_key = "LockID"
  name = "state_lock"
  billing_mode = "PAY_PER_REQUEST"
 
 attribute {
   type = "S"
   name = "LockID"

 }
}
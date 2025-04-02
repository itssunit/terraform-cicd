terraform {
  backend "s3" {
    bucket         = "terraform-state-prod-1234567890"   # Ensure this exists
    key            = "terraform/state.tfstate"     # Ensure it's correctly defined
    region         = "us-east-1"                   # Your AWS region
    dynamodb_table = "terraform-state-locks"        # Ensure this exists
    encrypt        = true
  }
}


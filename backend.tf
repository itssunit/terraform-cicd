terraform {
  backend "s3" {
    bucket = "tf-demo-locking"
    key = "staging/terraform.tfstate"
    region = "us-east-1"
    encrypt = true

  }
}
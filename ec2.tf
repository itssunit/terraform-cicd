resource "aws_instance" "TF" {
  instance_type = "t2.micro" 
  ami = "ami-00a929b66ed6e0de6"
}

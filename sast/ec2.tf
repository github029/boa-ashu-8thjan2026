terraform {
  required_version = "~> 1.13.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "Myvec2" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t2.micro"

  availability_zone = "us-east-1a"

  tags = {
    name = "bad-instance"
  }
}
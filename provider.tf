terraform {
  required_version = "~> 1.13.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
  }
  # terraform tfstate file remote backend section 
  backend "s3" {
    bucket = "ashutoshh-jan26-terraform"
    key = "dev/veerg/terraform.tfstate"
    encrypt = true
    region = "us-west-1"
    dynamodb_table = "ashutoshh-locking-table1"
    
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1" # additional changes
}

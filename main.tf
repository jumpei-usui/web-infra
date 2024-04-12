terraform {
  backend "s3" {
    bucket = "jumpei-usui-terraform-state"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"

  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">=1.2.0"
}

provider "aws" {
  region = "ap-northeast-1"
}

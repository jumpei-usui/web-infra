terraform {
  backend "s3" {
    bucket = "usui-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"

  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.45"
    }
  }
  required_version = ">=1.8.0"
}

provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "./modules/network"
}

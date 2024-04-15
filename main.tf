terraform {
  backend "s3" {
    bucket = "jumpei-usui-terraform-state"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"

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
  region = "ap-northeast-1"
}

module "network" {
  source = "./modules/network"
}

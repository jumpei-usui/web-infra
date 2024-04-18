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

module "database" {
  source             = "./modules/database"
  engine_version     = "8.0.mysql_aurora.3.04.2"
  cluster_identifier = "${var.product_name}-database"
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnet_ids
  subnet_id          = module.network.public_subnet_id
  key_name           = "web-infra"
  cidr_blocks        = var.cidr_blocks
}

module "api" {
  source       = "./modules/api"
  product_name = var.product_name
}

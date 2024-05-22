terraform {
  backend "s3" {
    bucket = "usuijuice-terraform-state"
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
  region = var.region
}

data "aws_caller_identity" "this" {}

module "network" {
  source             = "./modules/network"
  availability_zones = var.availability_zones
}

module "certificate" {
  source      = "./modules/certificate"
  domain_name = var.domain_name
}

module "firewall" {
  source      = "./modules/firewall"
  cidr_blocks = var.cidr_blocks
}

module "frontend" {
  source              = "./modules/frontend"
  product_name        = var.product_name
  domain_name         = var.domain_name
  zone_id             = module.certificate.zone_id
  acm_certificate_arn = module.certificate.frontend_acm_certificate_arn
  web_acl_arn         = module.firewall.web_acl_arn
}

module "database" {
  source                     = "./modules/database"
  region                     = var.region
  product_name               = var.product_name
  vpc_id                     = module.network.vpc_id
  subnet_id                  = module.network.private_subnet_id
  subnet_ids                 = module.network.private_subnet_ids
  private_subnet_cidr_blocks = module.network.private_subnet_cidr_blocks
}

module "api" {
  source                        = "./modules/api"
  region                        = var.region
  product_name                  = var.product_name
  domain_name                   = var.domain_name
  account_id                    = data.aws_caller_identity.this.account_id
  vpc_id                        = module.network.vpc_id
  private_subnet_ids            = module.network.private_subnet_ids
  public_subnet_ids             = module.network.public_subnet_ids
  vpc_default_security_group_id = module.network.vpc_default_security_group_id
  zone_id                       = module.certificate.zone_id
  api_acm_certificate_arn       = module.certificate.api_acm_certificate_arn
  alb_acm_certificate_arn       = module.certificate.alb_acm_certificate_arn
  web_acl_arn                   = module.firewall.web_acl_arn
  rds_cluster_endpoint          = module.database.rds_cluster_endpoint
}

module "auth" {
  source        = "./modules/auth"
  product_name  = var.product_name
  callback_urls = ["http://localhost:3000", "https://${var.domain_name}"]
  logout_urls   = ["http://localhost:3000", "https://${var.domain_name}"]
  metadata_url  = var.metadata_url
}

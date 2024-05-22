variable "region" {
  description = "AWS Region where the provider will operate"
  type        = string
}

variable "product_name" {
  description = "The name of the product"
  type        = string
}

variable "domain_name" {
  description = "This is the name of the hosted zone"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID number of the account that owns or contains the calling entity"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  type        = string
}

variable "zone_id" {
  description = "The Hosted Zone ID"
  type        = string
}

variable "api_acm_certificate_arn" {
  description = "ARN of the certificate"
  type        = string
}

variable "alb_acm_certificate_arn" {
  description = "ARN of the certificate"
  type        = string
}

variable "web_acl_arn" {
  description = "The ARN of the WAF WebACL"
  type        = string
}

variable "rds_cluster_endpoint" {
  description = "DNS address of the RDS instance"
  type        = string
}

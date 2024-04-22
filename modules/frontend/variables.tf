variable "product_name" {
  description = "The name of the product"
  type        = string
}

variable "domain_name" {
  description = "This is the name of the hosted zone"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the certificate"
  type        = string
}

variable "zone_id" {
  description = "The Hosted Zone ID"
  type        = string
}

variable "web_acl_arn" {
  description = "The ARN of the WAF WebACL"
  type        = string
}

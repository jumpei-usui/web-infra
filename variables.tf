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

variable "cidr_blocks" {
  description = "List of CIDR blocks"
  type        = list(string)
}

variable "metadata_url" {
  description = "The URL of the SAML metadata"
  type        = string
}

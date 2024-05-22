variable "product_name" {
  description = "The name of the product"
  type        = string
}

variable "metadata_url" {
  description = "The URL of the SAML metadata"
  type        = string
}

variable "callback_urls" {
  description = "List of allowed callback URLs for the identity providers"
  type        = list(string)
}

variable "logout_urls" {
  description = "List of allowed logout URLs for the identity providers"
  type        = list(string)
}

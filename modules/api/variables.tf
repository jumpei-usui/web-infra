variable "product_name" {
  description = "The name of the product"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  type        = string
}

variable "public_subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "product_name" {
  description = "The name of the product"
  type        = string
}

variable "max_capacity" {
  description = "Maximum capacity for an Aurora DB cluster in serverless DB engine mode"
  type        = number
  default     = 1.0
}

variable "min_capacity" {
  description = "Minimum capacity for an Aurora DB cluster in serverless DB engine mode"
  type        = number
  default     = 0.5
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "subnet_id" {
  description = "The ID of the subnet"
  type        = string
}

variable "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks"
  type        = list(string)
}

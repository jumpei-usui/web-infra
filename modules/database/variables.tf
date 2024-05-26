variable "min_capacity" {
  description = "Minimum capacity for an Aurora DB cluster in serverless DB engine mode"
  type        = number
  default     = 0.5
}

variable "max_capacity" {
  description = "Maximum capacity for an Aurora DB cluster in serverless DB engine mode"
  type        = number
  default     = 1.0
}

variable "autoscaling_min_capacity" {
  description = "Min capacity of the scalable target"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Max capacity of the scalable target"
  type        = number
  default     = 1
}

variable "region" {
  description = "AWS Region where the provider will operate"
  type        = string
}

variable "product_name" {
  description = "The name of the product"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
}

variable "private_subnet_cidr_blocks" {
  description = "List of CIDR blocks"
  type        = list(string)
}

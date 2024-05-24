output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "A list of VPC subnet IDs"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "private_subnet_cidr_blocks" {
  description = "The IPv4 CIDR block of the subnet"
  value       = [aws_subnet.private_1.cidr_block, aws_subnet.private_2.cidr_block]
}

output "public_subnet_ids" {
  description = "A list of VPC subnet IDs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = aws_vpc.this.default_security_group_id
}

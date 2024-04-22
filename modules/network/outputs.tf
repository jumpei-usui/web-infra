output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "A list of VPC subnet IDs"
  value       = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "public_subnet_id" {
  description = "The ID of the subnet"
  value       = aws_subnet.public_1.id
}

output "public_subnet_ids" {
  description = "A list of VPC subnet IDs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = aws_vpc.this.default_security_group_id
}

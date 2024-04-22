output "rds_cluster_endpoint" {
  description = "DNS address of the RDS instance"
  value       = aws_rds_cluster.this.endpoint
}

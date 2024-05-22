output "zone_id" {
  description = "The Hosted Zone ID"
  value       = data.aws_route53_zone.this.zone_id
}

output "frontend_acm_certificate_arn" {
  description = "ARN of the certificate"
  value       = aws_acm_certificate.frontend.arn
}

output "api_acm_certificate_arn" {
  description = "ARN of the certificate"
  value       = aws_acm_certificate.api.arn
}

output "alb_acm_certificate_arn" {
  description = "ARN of the certificate"
  value       = aws_acm_certificate.alb.arn
}

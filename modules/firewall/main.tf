resource "aws_wafv2_ip_set" "this" {
  name               = "IPSet"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.cidr_blocks
}

resource "aws_wafv2_web_acl" "this" {
  name  = "IPSetWebACL"
  scope = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "IPSetRule"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.this.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "IPSetRuleMetric"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "IPSetWebACLMetric"
    sampled_requests_enabled   = false
  }
}

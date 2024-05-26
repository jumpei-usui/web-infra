resource "aws_ecr_repository" "this" {
  name = "${var.product_name}-api"
}

data "aws_cloudfront_cache_policy" "this" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "this" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_distribution" "this" {
  enabled = "true"

  origin {
    origin_id   = "alb.${var.domain_name}"
    domain_name = "alb.${var.domain_name}"

    custom_origin_config {
      origin_protocol_policy   = "https-only"
      http_port                = 80
      https_port               = 443
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 30
      origin_keepalive_timeout = 5
    }

    connection_attempts = 3
    connection_timeout  = 10
  }

  default_cache_behavior {
    target_origin_id         = "alb.${var.domain_name}"
    compress                 = true
    viewer_protocol_policy   = "https-only"
    allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods           = ["GET", "HEAD"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.this.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.this.id
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["api.${var.domain_name}"]

  viewer_certificate {
    acm_certificate_arn      = var.api_acm_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  http_version    = "http2"
  is_ipv6_enabled = true
  web_acl_id      = var.web_acl_arn
}

resource "aws_route53_record" "cloudfront_ipv4" {
  zone_id = var.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "cloudfront_ipv6" {
  zone_id = var.zone_id
  name    = "api.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "this" {
  vpc_id = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }
}

resource "aws_lb" "this" {
  load_balancer_type = "application"
  internal           = false
  ip_address_type    = "ipv4"
  subnets            = var.public_subnet_ids
  security_groups    = [var.vpc_default_security_group_id, aws_security_group.this.id]
}

resource "aws_lb_target_group" "this" {
  target_type      = "ip"
  protocol         = "HTTP"
  port             = 80
  ip_address_type  = "ipv4"
  vpc_id           = var.vpc_id
  protocol_version = "HTTP1"

  health_check {
    protocol            = "HTTP"
    path                = "/healthy"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  protocol          = "HTTPS"
  port              = 443
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.alb_acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_route53_record" "alb_ipv4" {
  zone_id = var.zone_id
  name    = "alb.${var.domain_name}"
  type    = "A"

  alias {
    name                   = "dualstack.${aws_lb.this.dns_name}"
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alb_ipv6" {
  zone_id = var.zone_id
  name    = "alb.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = "dualstack.${aws_lb.this.dns_name}"
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = false
  }
}

data "aws_iam_policy" "ecs_task_execution" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ECSTaskExecution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  managed_policy_arns = [data.aws_iam_policy.ecs_task_execution.arn]
}

resource "aws_iam_role" "ecs_database_connection" {
  name = "ECSDatabaseConnection"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  inline_policy {
    name = "DatabaseConnectionPolicy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "rds-db:connect"
          ]
          Resource = [
            "arn:aws:rds-db:${var.region}:${var.account_id}:dbuser:*/*"
          ]
        },
      ]
    })
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${var.product_name}-api"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.product_name}-cluster"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.product_name}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_database_connection.arn
  container_definitions = jsonencode([
    {
      name  = "${var.product_name}-api"
      image = "hello-world"
    }
  ])

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_ecs_service" "this" {
  name                = "${var.product_name}-service"
  cluster             = aws_ecs_cluster.this.id
  launch_type         = "FARGATE"
  platform_version    = "LATEST"
  task_definition     = aws_ecs_task_definition.this.arn_without_revision
  scheduling_strategy = "REPLICA"
  desired_count       = var.autoscaling_min_capacity

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.vpc_default_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    container_name   = "${var.product_name}-api"
    container_port   = 80
    target_group_arn = aws_lb_target_group.this.arn
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = var.autoscaling_min_capacity
  max_capacity       = var.autoscaling_max_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "ECSServiceAverageCPUUtilization"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_out_cooldown = 300
    scale_in_cooldown  = 300
    disable_scale_in   = false
  }
}

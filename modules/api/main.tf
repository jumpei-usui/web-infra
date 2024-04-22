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

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_ecr_repository" "this" {
  name = "${var.product_name}-api"
}

resource "aws_ecs_cluster" "this" {
  name = "${var.product_name}-cluster"
}

resource "aws_ecs_service" "this" {
  name             = "${var.product_name}-service"
  cluster          = aws_ecs_cluster.this.id
  launch_type      = "FARGATE"
  platform_version = "LATEST"
  # task_definition     = 
  scheduling_strategy = "REPLICA"
  desired_count       = 1

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
    container_name   = "test"
    container_port   = 80
    target_group_arn = aws_lb_target_group.this.arn
  }
}

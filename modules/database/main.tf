resource "aws_security_group" "rds" {
  vpc_id = var.vpc_id
}

resource "aws_security_group" "ec2" {
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "rds_private_subnet" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = var.private_subnet_cidr_blocks
  security_group_id = aws_security_group.rds.id
}

resource "aws_security_group_rule" "rds_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
  security_group_id        = aws_security_group.rds.id
}

resource "aws_security_group_rule" "ec2_rds" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  security_group_id        = aws_security_group.ec2.id
}

resource "aws_db_subnet_group" "this" {
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "this" {
  apply_immediately                   = true
  cluster_identifier                  = "${var.product_name}-database"
  engine                              = "aurora-mysql"
  engine_version                      = var.engine_version
  master_username                     = "admin"
  manage_master_user_password         = true
  db_subnet_group_name                = aws_db_subnet_group.this.name
  iam_database_authentication_enabled = true
  storage_encrypted                   = true
  deletion_protection                 = true
  vpc_security_group_ids              = [aws_security_group.rds.id]

  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }
}

resource "aws_iam_role" "this" {
  name = "RDSMonitoringRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = ""
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]
}

resource "aws_rds_cluster_instance" "this" {
  count                        = var.autoscaling_min_capacity
  cluster_identifier           = aws_rds_cluster.this.id
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.this.engine
  engine_version               = aws_rds_cluster.this.engine_version
  db_subnet_group_name         = aws_db_subnet_group.this.name
  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.this.arn
}

resource "aws_appautoscaling_target" "this" {
  service_namespace  = "rds"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  resource_id        = "cluster:${aws_rds_cluster.this.id}"
  min_capacity       = var.autoscaling_min_capacity
  max_capacity       = var.autoscaling_max_capacity
}

resource "aws_appautoscaling_policy" "this" {
  name               = "RDSReaderAverageCPUUtilization"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_security_group" "ssm" {
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ssm_ec2" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2.id
  security_group_id        = aws_security_group.ssm.id
}

resource "aws_security_group_rule" "ec2_ssm" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ssm.id
  security_group_id        = aws_security_group.ec2.id
}

resource "aws_vpc_endpoint" "ssm" {
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [var.subnet_id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.ssm.id]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [var.subnet_id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.ssm.id]
}

resource "aws_vpc_endpoint" "ec2messages" {
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  vpc_id              = var.vpc_id
  subnet_ids          = [var.subnet_id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.ssm.id]
}

data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]
  }
}

resource "aws_iam_role" "ec2" {
  name = "EC2SessionManagerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_instance_profile" "this" {
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.this.id
  instance_type          = "t4g.nano"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.this.id
}

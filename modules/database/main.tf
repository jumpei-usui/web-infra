resource "aws_security_group" "rds" {
  vpc_id = var.vpc_id
}

resource "aws_security_group" "ec2" {
  vpc_id = var.vpc_id
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
  cluster_identifier          = var.cluster_identifier
  engine                      = "aurora-mysql"
  engine_version              = var.engine_version
  master_username             = "admin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.this.name
  storage_encrypted           = true
  deletion_protection         = true
  vpc_security_group_ids      = [aws_security_group.rds.id]

  serverlessv2_scaling_configuration {
    max_capacity = var.max_capacity
    min_capacity = var.min_capacity
  }
}

resource "aws_iam_role" "this" {
  name = "rds-monitoring-role"

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
  count                        = 2
  cluster_identifier           = aws_rds_cluster.this.id
  instance_class               = "db.serverless"
  engine                       = aws_rds_cluster.this.engine
  engine_version               = aws_rds_cluster.this.engine_version
  db_subnet_group_name         = aws_db_subnet_group.this.name
  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn          = aws_iam_role.this.arn
}

data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]
  }
}

resource "aws_security_group" "ssh" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.this.id
  instance_type          = "t4g.nano"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id, aws_security_group.ssh.id]
}

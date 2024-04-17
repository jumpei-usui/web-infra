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

  serverlessv2_scaling_configuration {
    max_capacity = var.max_capacity
    min_capacity = var.min_capacity
  }
}

resource "aws_rds_cluster_instance" "this" {
  count                = 2
  cluster_identifier   = aws_rds_cluster.this.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.this.engine
  engine_version       = aws_rds_cluster.this.engine_version
  db_subnet_group_name = aws_db_subnet_group.this.name
}

data "aws_ami" "this" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-arm64"]
  }
}

resource "aws_security_group" "this" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = []
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.this.id
  instance_type          = "t4g.nano"
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.this.id]
}

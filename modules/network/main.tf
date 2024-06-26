resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zones[0]
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = var.availability_zones[0]
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = var.availability_zones[1]
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = var.availability_zones[1]
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_default_route_table" "public" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_default_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_default_route_table.public.id
}

resource "aws_eip" "public_1" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "public_2" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "public_1" {
  allocation_id = aws_eip.public_1.id
  subnet_id     = aws_subnet.public_1.id

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "public_2" {
  allocation_id = aws_eip.public_2.id
  subnet_id     = aws_subnet.public_2.id

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_1.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public_2.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

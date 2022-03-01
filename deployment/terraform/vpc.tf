resource "aws_vpc" "cadet" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name        = "${title(var.env)} Cadet VPC"
    Environment = var.env
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.cadet.id
  availability_zone       = "ap-southeast-1a"
  cidr_block              = cidrsubnet(aws_vpc.cadet.cidr_block, 8, 0)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${title(var.env)} Cadet Private Subnet A"
    Environment = var.env
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.cadet.id
  availability_zone       = "ap-southeast-1b"
  cidr_block              = cidrsubnet(aws_vpc.cadet.cidr_block, 8, 1)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${title(var.env)} Cadet Private Subnet B"
    Environment = var.env
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.cadet.id
  availability_zone       = "ap-southeast-1a"
  cidr_block              = cidrsubnet(aws_vpc.cadet.cidr_block, 8, 2)
  map_public_ip_on_launch = true

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.cadet.ipv6_cidr_block, 8, 2)
  assign_ipv6_address_on_creation = true

  tags = {
    Name        = "${title(var.env)} Cadet Public Subnet A"
    Environment = var.env
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.cadet.id
  availability_zone       = "ap-southeast-1b"
  cidr_block              = cidrsubnet(aws_vpc.cadet.cidr_block, 8, 3)
  map_public_ip_on_launch = true

  ipv6_cidr_block                 = cidrsubnet(aws_vpc.cadet.ipv6_cidr_block, 8, 3)
  assign_ipv6_address_on_creation = true

  tags = {
    Name        = "${title(var.env)} Cadet Public Subnet B"
    Environment = var.env
  }
}

resource "aws_security_group" "db" {
  name_prefix = "${var.env}-cadet-db-"
  vpc_id      = aws_vpc.cadet.id

  tags = {
    Name        = "${title(var.env)} Cadet DB Security Group"
    Environment = var.env
  }

  ingress {
    description     = "Postgres from API"
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.api.id]
  }
}

resource "aws_security_group" "api" {
  name_prefix = "${var.env}-cadet-api-"
  vpc_id      = aws_vpc.cadet.id

  tags = {
    Name        = "${title(var.env)} Cadet API Security Group"
    Environment = var.env
  }

  egress {
    description      = "Any to internet"
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description     = "HTTP from API Load Balancer"
    protocol        = "tcp"
    from_port       = 4000
    to_port         = 4000
    security_groups = [aws_security_group.lb.id]
  }
}

resource "aws_security_group" "lb" {
  name_prefix = "${var.env}-cadet-lb-"
  vpc_id      = aws_vpc.cadet.id

  tags = {
    Name        = "${title(var.env)} Cadet API Load Balancer Security Group"
    Environment = var.env
  }

  egress {
    description      = "Any to internet"
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from internet"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_internet_gateway" "cadet" {
  vpc_id = aws_vpc.cadet.id

  tags = {
    Name        = "${title(var.env)} Cadet Internet Gateway"
    Environment = var.env
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cadet.id

  tags = {
    Name        = "Cadet ${title(var.env)} Public"
    Environment = var.env
  }
}

resource "aws_route" "public_all_ipv6" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.cadet.id
}

resource "aws_route" "public_all_ipv4" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cadet.id
}

resource "aws_route_table_association" "public_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_a.id
}

resource "aws_route_table_association" "public_b" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_b.id
}

resource "aws_vpc" "cadet" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name        = "${title(var.env)} Cadet VPC"
    Environment = "${var.env}"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = "${aws_vpc.cadet.id}"
  availability_zone       = "ap-southeast-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags {
    Name        = "${title(var.env)} Cadet Public Subnet A"
    Environment = "${var.env}"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = "${aws_vpc.cadet.id}"
  availability_zone       = "ap-southeast-1b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags {
    Name        = "${title(var.env)} Cadet Public Subnet B"
    Environment = "${var.env}"
  }
}

resource "aws_security_group" "api" {
  name_prefix = "${var.env}-cadet-api-"
  vpc_id      = "${aws_vpc.cadet.id}"

  tags {
    Name        = "${title(var.env)} Cadet API Security Group"
    Environment = "${var.env}"
  }
}

resource "aws_security_group" "api_lb" {
  name_prefix = "${var.env}-cadet-lb-"
  vpc_id      = "${aws_vpc.cadet.id}"

  tags {
    Name        = "${title(var.env)} Cadet API Load Balancer Security Group"
    Environment = "${var.env}"
  }
}

resource "aws_security_group_rule" "api_egress" {
  security_group_id = "${aws_security_group.api.id}"
  description       = "Allow Public Egress Access"

  type        = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_lb_egress" {
  security_group_id = "${aws_security_group.api_lb.id}"
  description       = "Allow Public Egress Access"

  type        = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_ingress_http" {
  security_group_id = "${aws_security_group.api.id}"
  description       = "Allow HTTP Access from Load Balancer"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 80
  to_port                  = 80
  source_security_group_id = "${aws_security_group.api_lb.id}"
}

resource "aws_security_group_rule" "api_lb_ingress_http" {
  security_group_id = "${aws_security_group.api_lb.id}"
  description       = "Allow Public HTTP Access"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_ingress_ssh" {
  security_group_id = "${aws_security_group.api.id}"
  description       = "Allow Public SSH Access"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_internet_gateway" "cadet" {
  vpc_id = "${aws_vpc.cadet.id}"

  tags {
    Name        = "${title(var.env)} Cadet Internet Gateway"
    Environment = "${var.env}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.cadet.id}"

  tags {
    Name        = "Cadet ${title(var.env)} Public"
    Environment = "${var.env}"
  }
}

resource "aws_route" "public_all_ipv6" {
  route_table_id              = "${aws_route_table.public.id}"
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = "${aws_internet_gateway.cadet.id}"
}

resource "aws_route" "public_all_ipv4" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.cadet.id}"
}

resource "aws_route_table_association" "public_a" {
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${aws_subnet.public_a.id}"
}

resource "aws_route_table_association" "public_b" {
  route_table_id = "${aws_route_table.public.id}"
  subnet_id      = "${aws_subnet.public_b.id}"
}

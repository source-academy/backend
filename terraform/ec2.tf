data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_launch_template" "api" {
  name_prefix             = "${var.env}-cadet-api-"
  image_id                = data.aws_ami.ubuntu.id
  instance_type           = var.ec2_instance_type
  key_name                = var.api_ssh_key_name
  disable_api_termination = true
  ebs_optimized           = true

  iam_instance_profile {
    name = aws_iam_instance_profile.api.name
  }

  network_interfaces {
    ipv6_address_count          = 1
    associate_public_ip_address = true
    security_groups             = [aws_security_group.api.id]
  }

  update_default_version = true
}

resource "aws_autoscaling_group" "api" {
  depends_on = [aws_internet_gateway.cadet]

  name = aws_launch_template.api.name
  launch_template {
    id      = aws_launch_template.api.id
    version = "$Latest"
  }

  target_group_arns = [
    aws_lb_target_group.api.arn
  ]

  vpc_zone_identifier = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  min_size = var.min_instance_count
  max_size = var.max_instance_count

  health_check_type         = "EC2"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${title(var.env)} Cadet API"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.env
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "api" {
  depends_on = [aws_internet_gateway.cadet]

  name               = "${var.env}-cadet-api"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]

  tags = {
    Name        = "${title(var.env)} Cadet API Load Balancer"
    Environment = var.env
  }
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = aws_lb.api.arn
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_lb_target_group" "api" {
  name     = "${var.env}-cadet-api"
  vpc_id   = aws_vpc.cadet.id
  protocol = "HTTP"
  port     = 4000

  tags = {
    Name        = "${title(var.env)} Cadet API Target Group"
    Environment = var.env
  }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3a.nano"

  tags = {
    Name        = "${title(var.env)} Cadet Bastion"
    Environment = var.env
  }

  vpc_security_group_ids      = [aws_security_group.bastion.id]
  subnet_id                   = aws_subnet.public_a.id
  associate_public_ip_address = true
  ipv6_address_count          = 1
  ebs_optimized               = true
  key_name                    = var.bastion_ssh_key_name
}

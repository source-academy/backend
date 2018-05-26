resource "aws_key_pair" "api" {
  key_name   = "${var.env}-api-ssh"
  public_key = "${var.ssh_public_key}"
}

resource "aws_launch_configuration" "api" {
  name_prefix                 = "${var.env}-cadet-api-"
  image_id                    = "${var.ami_id}"
  instance_type               = "${var.instance_type}"
  security_groups             = ["${aws_security_group.api.id}"]
  key_name                    = "${aws_key_pair.api.key_name}"
  iam_instance_profile        = "${aws_iam_instance_profile.api.name}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "api" {
  depends_on = ["aws_internet_gateway.cadet"]

  name                 = "${aws_launch_configuration.api.name}"
  launch_configuration = "${aws_launch_configuration.api.name}"

  target_group_arns = [
    "${aws_lb_target_group.api.arn}",
  ]

  vpc_zone_identifier = [
    "${aws_subnet.public_a.id}",
    "${aws_subnet.public_b.id}",
  ]

  min_size = "${var.min_instance_count}"
  max_size = "${var.max_instance_count}"

  // todo(evansb) change to ELB once AMI is deployed
  health_check_type         = "EC2"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "${title(var.env)} Cadet API"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.env}"
    propagate_at_launch = true
  }
}

resource "aws_lb" "api" {
  depends_on = ["aws_internet_gateway.cadet"]

  name               = "${var.env}-cadet-api"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.api_lb.id}"]

  subnets = [
    "${aws_subnet.public_a.id}",
    "${aws_subnet.public_b.id}",
  ]

  tags {
    Name        = "${title(var.env)} Cadet API Load Balancer"
    Environment = "${var.env}"
  }
}

resource "aws_lb_listener" "api" {
  load_balancer_arn = "${aws_lb.api.arn}"
  protocol          = "HTTP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.api.arn}"
  }
}

resource "aws_lb_target_group" "api" {
  name     = "${var.env}-cadet-api"
  vpc_id   = "${aws_vpc.cadet.id}"
  protocol = "HTTP"
  port     = 80

  tags {
    Name        = "${title(var.env)} Cadet API Target Group"
    Environment = "${var.env}"
  }
}

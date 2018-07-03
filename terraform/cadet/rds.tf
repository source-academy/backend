resource "aws_db_subnet_group" "main" {
  name = "main"
  subnet_ids = ["${aws_subnet.private_a.id}", "${aws_subnet.private_b.id}"]

  tags {
    Name        = "${title(var.env)} Cadet DB"
    Environment = "${var.env}"
  }
}

resource "aws_db_instance" "db" {
  name                   = "${title(var.env)}CadetDB"
  instance_class         = "${var.rds_instance_class}"
  db_subnet_group_name   = "${aws_db_subnet_group.main.name}"
  vpc_security_group_ids = ["${aws_security_group.db.id}"]
  allocated_storage      = "${var.rds_allocated_storage}"
  storage_type           = "gp2"
  engine                 = "postgres"
  username               = "postgres"
  password               = "${var.rds_password}"
  port                   = 5432
  publicly_accessible    = false

  tags {
    Name        = "${title(var.env)} Cadet DB"
    Environment = "${var.env}"
  }

  lifecycle {
    ignore_changes = ["password"]
  }
}

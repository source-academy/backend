resource "random_password" "db_password" {
  length           = 64
  override_special = "~!#$%^&*()_+-=[]{}|;:,.<>?"
}

resource "aws_db_subnet_group" "db" {
  name       = "${var.env}-cadet-db"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name        = "${title(var.env)} Cadet DB"
    Environment = var.env
  }
}

resource "aws_db_instance" "db" {
  identifier_prefix            = "${var.env}-cadet-db-"
  name                         = "cadet_${var.env}"
  instance_class               = var.rds_instance_class
  db_subnet_group_name         = aws_db_subnet_group.db.name
  vpc_security_group_ids       = [aws_security_group.db.id]
  allocated_storage            = var.rds_allocated_storage
  storage_type                 = "gp2"
  engine                       = "postgres"
  engine_version               = "13.3"
  username                     = "postgres"
  password                     = random_password.db_password.result
  port                         = 5432
  publicly_accessible          = false
  backup_retention_period      = 14
  backup_window                = "17:00-18:00"
  maintenance_window           = "sun:18:00-sun:22:00"
  deletion_protection          = true
  performance_insights_enabled = true
  monitoring_interval          = 60

  tags = {
    Name        = "${title(var.env)} Cadet DB"
    Environment = var.env
  }
}

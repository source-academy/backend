resource "aws_secretsmanager_secret" "db" {
  name = "${var.env}-cadet-db"

  tags = {
    "Environment" = var.env,
    "Name"        = "${title(var.env)} Cadet DB"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username             = aws_db_instance.db.username,
    password             = aws_db_instance.db.password,
    engine               = aws_db_instance.db.engine,
    host                 = aws_db_instance.db.address,
    port                 = aws_db_instance.db.port,
    dbname               = aws_db_instance.db.name,
    dbInstanceIdentifier = aws_db_instance.db.id
  })
}

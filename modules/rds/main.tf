resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}:;,.<>?"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

data "aws_secretsmanager_secret" "db" {
  name = "postgres-dbs-top-secret"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = data.aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "postgres-subnet-group"
  subnet_ids = var.db_subnets
}

resource "aws_db_instance" "postgres" {
  identifier = "three-tier-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class = "db.t3.micro"

  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username

  password = random_password.db.result

  multi_az = false

  publicly_accessible = false

  skip_final_snapshot                   = true
  storage_encrypted                     = true
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  db_subnet_group_name                  = aws_db_subnet_group.main.name
  vpc_security_group_ids                = [var.rds_sg]
  backup_retention_period               = 1
  deletion_protection                   = false
}

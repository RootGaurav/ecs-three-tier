output "db_host" {
  value = aws_db_instance.postgres.address
}

output "db_port" {
  value = aws_db_instance.postgres.port
}

output "secret_arn" {
  value = data.aws_secretsmanager_secret.db.arn
}

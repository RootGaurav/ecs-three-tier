output "grafana_ip" {
  value = aws_instance.grafana.public_ip
}

output "influxdb_ip" {
  value = aws_instance.influxdb.private_ip
}

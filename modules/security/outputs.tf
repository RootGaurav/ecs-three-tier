output "alb_sg" {
  value = aws_security_group.alb.id
}

output "frontend_sg" {
  value = aws_security_group.frontend.id
}

output "backend_sg" {
  value = aws_security_group.backend.id
}

output "rds_sg" {
  value = aws_security_group.rds.id
}

output "jenkins_sg" {
  value = aws_security_group.jenkins.id
}

output "grafana_sg" {
  value = aws_security_group.grafana.id
}

output "kibana_sg" {
  value = aws_security_group.kibana.id
}

output "influxdb_sg" {
  value = aws_security_group.influxdb.id
}

output "ecs_nodes_sg" {
  value = aws_security_group.ecs_nodes.id
}
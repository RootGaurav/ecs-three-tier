output "frontend_capacity_provider_name" {
  value = aws_ecs_capacity_provider.frontend.name
}

output "backend_capacity_provider_name" {
  value = aws_ecs_capacity_provider.backend.name
}

output "frontend_repo_url" {
  value = data.aws_ecr_repository.frontend.repository_url
}

output "backend_repo_url" {
  value = data.aws_ecr_repository.backend.repository_url
}

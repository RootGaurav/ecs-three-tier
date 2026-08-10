data "aws_ecr_repository" "frontend" {
  name = "frontend"
}

data "aws_ecr_repository" "backend" {
  name = "backend"
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = data.aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep latest 10 images"

      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }

      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = data.aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep latest 10 images"

      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }

      action = {
        type = "expire"
      }
    }]
  })
}

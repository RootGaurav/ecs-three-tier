data "aws_iam_role" "ecs_execution" {
  name = "ecs-task-execution-role"
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = data.aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "secrets" {
  name = "ecs-secrets-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "secret_attach" {
  role       = data.aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.secrets.arn
}

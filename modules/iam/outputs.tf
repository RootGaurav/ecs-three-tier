output "ecs_execution_role_arn" {
  value = data.aws_iam_role.ecs_execution.arn
}

output "ec2_instance_profile" {
  value = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_role_arn" {
  value = aws_iam_role.ec2_role.arn
}
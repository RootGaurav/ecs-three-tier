resource "aws_ecs_cluster" "main" {
  name = "three-tier-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

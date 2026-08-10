variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "instance_profile_arn" {
  description = "ARN of the ECS instance profile"
  type        = string
}

variable "ecs_node_sg" {
  description = "Security group ID for ECS nodes"
  type        = string
}

variable "private_subnets" {
  description = "Private subnets for the ECS Auto Scaling Group"
  type        = list(string)
}

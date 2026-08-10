variable "cluster_id" {
  description = "ID of the ECS cluster"
  type        = string
}

variable "frontend_tg_arn" {
  description = "Target group ARN for the frontend service"
  type        = string
}

variable "backend_tg_arn" {
  description = "Target group ARN for the backend service"
  type        = string
}

variable "frontend_image" {
  description = "Docker image URI for the frontend task"
  type        = string
}

variable "backend_image" {
  description = "Docker image URI for the backend task"
  type        = string
}

variable "execution_role_arn" {
  description = "ECS task execution role ARN"
  type        = string
}

variable "subnets" {
  description = "Subnets for ECS tasks"
  type        = list(string)
}

variable "frontend_sg_id" {
  description = "Security group ID for frontend tasks"
  type        = string
}

variable "backend_sg_id" {
  description = "Security group ID for backend tasks"
  type        = string
}

variable "frontend_capacity_provider_name" {
  description = "Capacity provider for frontend service"
  type        = string
}

variable "backend_capacity_provider_name" {
  description = "Capacity provider for backend service"
  type        = string
}

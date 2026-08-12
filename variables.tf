variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Project name used in resource tags"
  type        = string
  default     = "three-tier"
}

variable "my_ip" {
  description = "Office/Home IP"
  type        = string
}

variable "alert_email" {
  description = "Email address for SNS alert subscriptions"
  type        = string
}

variable "db_name" {
  description = "Database name used by RDS and ECS services"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database username used by RDS and ECS services"
  type        = string
  default     = "postgres"
}

variable "key_name" {
  description = "Key pair name for EC2 instances"
  type        = string
  default     = "eks-key"
}

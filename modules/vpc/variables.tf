variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "project_name" {
  description = "Project name used in resource tags"
  type        = string
  default     = "three-tier"
}

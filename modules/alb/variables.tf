variable "vpc_id" {
  description = "VPC ID for the ALB target groups"
  type        = string
}

variable "public_subnets" {
  description = "Subnets for the ALB"
  type        = list(string)
}

variable "alb_sg" {
  description = "Security group ID for the ALB"
  type        = string
}

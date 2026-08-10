variable "vpc_id" {
  description = "VPC ID where the security groups will be created"
  type        = string
}

variable "my_ip" {
  description = "Your public IP/CIDR"
  type        = string
}

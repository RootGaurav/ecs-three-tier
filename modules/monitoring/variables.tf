variable "cluster_name" {
  description = "ECS cluster name for CloudWatch dimensions"
  type        = string
}

variable "alert_email" {
  description = "Email address for SNS alert subscriptions"
  type        = string
}

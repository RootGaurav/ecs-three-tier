variable "zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
}

variable "record_name" {
  description = "DNS record name"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name for alias record"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID for alias record"
  type        = string
}

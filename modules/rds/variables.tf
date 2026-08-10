variable "db_subnets" {
  description = "Subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "rds_sg" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

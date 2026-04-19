variable "aws_region" {
  description = "AWS region for the Aurora Express cluster"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "aurora-express-demo"
}

variable "environment" {
  description = "Environment name used for tagging and resource naming"
  type        = string
  default     = "dev"
}

variable "db_name" {
  description = "Initial database name to create inside the Aurora cluster"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Database role used by the application for IAM authentication"
  type        = string
  default     = "app_user"
}

variable "min_acu" {
  description = "Minimum Aurora Capacity Units. Zero means scale-to-zero when idle."
  type        = number
  default     = 0
}

variable "max_acu" {
  description = "Maximum Aurora Capacity Units"
  type        = number
  default     = 4
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection on the cluster"
  type        = bool
  default     = false
}

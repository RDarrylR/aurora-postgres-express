variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "aurora-traditional-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.42.0.0/20", "10.42.16.0/20", "10.42.32.0/20"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private database subnets (one per AZ)"
  type        = list(string)
  default     = ["10.42.128.0/20", "10.42.144.0/20", "10.42.160.0/20"]
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the database on port 5432"
  type        = list(string)
  default     = []
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Master database user"
  type        = string
  default     = "postgres"
}

variable "min_acu" {
  description = "Minimum Aurora Capacity Units"
  type        = number
  default     = 0.5
}

variable "max_acu" {
  description = "Maximum Aurora Capacity Units"
  type        = number
  default     = 4
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "17.4"
}

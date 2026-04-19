output "cluster_identifier" {
  description = "Aurora Express cluster identifier"
  value       = local.express_cluster_identifier
}

output "cluster_endpoint" {
  description = "Writer endpoint reachable over the internet through the Aurora internet access gateway"
  value       = data.aws_rds_cluster.express.endpoint
}

output "reader_endpoint" {
  description = "Reader endpoint for read replicas (if added later)"
  value       = data.aws_rds_cluster.express.reader_endpoint
}

output "database_name" {
  description = "App database name (must be created post-cluster via schema.sql - express config does not support --database-name)"
  value       = var.db_name
}

output "admin_user" {
  description = "Admin database user (IAM authentication is enabled by default for this user)"
  value       = "postgres"
}

output "app_iam_role_arn" {
  description = "ARN of the IAM role that can generate DB auth tokens for the app user"
  value       = aws_iam_role.app.arn
}

output "bootstrap_iam_role_arn" {
  description = "ARN of the bootstrap IAM role for one-time schema setup as postgres"
  value       = aws_iam_role.bootstrap.arn
}

output "connection_hint" {
  description = "Environment variables to export before running the Python samples"
  value = {
    DB_ENDPOINT = data.aws_rds_cluster.express.endpoint
    DB_NAME     = var.db_name
    DB_USER     = "postgres"
    AWS_REGION  = var.aws_region
  }
}

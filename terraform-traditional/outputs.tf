output "cluster_identifier" {
  value = aws_rds_cluster.main.cluster_identifier
}

output "cluster_endpoint" {
  value = aws_rds_cluster.main.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.main.reader_endpoint
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "security_group_id" {
  value = aws_security_group.db.id
}

output "db_subnet_group" {
  value = aws_db_subnet_group.main.name
}

output "master_password" {
  value     = random_password.master.result
  sensitive = true
}

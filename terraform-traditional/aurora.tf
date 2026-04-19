resource "random_password" "master" {
  length  = 32
  special = false
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = "${local.name_prefix}-cluster"

  engine         = "aurora-postgresql"
  engine_mode    = "provisioned"
  engine_version = var.engine_version
  database_name  = var.db_name

  master_username = var.db_user
  master_password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]

  iam_database_authentication_enabled = true

  storage_encrypted = true

  backup_retention_period  = 7
  preferred_backup_window  = "07:00-09:00"
  preferred_maintenance_window = "sun:05:00-sun:06:00"

  deletion_protection = false
  skip_final_snapshot = true

  serverlessv2_scaling_configuration {
    min_capacity             = var.min_acu
    max_capacity             = var.max_acu
    seconds_until_auto_pause = 3600
  }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${local.name_prefix}-writer"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  publicly_accessible = false
}

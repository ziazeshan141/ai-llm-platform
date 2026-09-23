# ---------------------------------------------------------
# RDS Subnet Group
# ---------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name = "${var.project_name}-${var.environment}-db-subnet-group"

  subnet_ids = var.database_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}


# ---------------------------------------------------------
# PostgreSQL RDS
# ---------------------------------------------------------

resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  # -------------------------------------------------------
  # Database Engine
  # -------------------------------------------------------

  engine         = "postgres"
  engine_version = var.engine_version

  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.master_username

  # AWS generates and stores the master password
  # in AWS Secrets Manager.
  manage_master_user_password = true


  # -------------------------------------------------------
  # Storage
  # -------------------------------------------------------

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  storage_type      = "gp3"
  storage_encrypted = true


  # -------------------------------------------------------
  # Networking
  # -------------------------------------------------------

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = [
    var.rds_security_group_id
  ]

  publicly_accessible = false

  port = 5432


  # -------------------------------------------------------
  # Availability
  # -------------------------------------------------------

  multi_az = var.multi_az


  # -------------------------------------------------------
  # Backups
  # -------------------------------------------------------

  backup_retention_period = var.backup_retention_period

  copy_tags_to_snapshot = true


  # -------------------------------------------------------
  # Maintenance
  # -------------------------------------------------------

  auto_minor_version_upgrade = true


  # -------------------------------------------------------
  # Protection
  # -------------------------------------------------------

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot

  final_snapshot_identifier = var.skip_final_snapshot ? null : (
    "${var.project_name}-${var.environment}-postgres-final"
  )


  # -------------------------------------------------------
  # Logging
  # -------------------------------------------------------

  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]


  # -------------------------------------------------------
  # Tags
  # -------------------------------------------------------

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}
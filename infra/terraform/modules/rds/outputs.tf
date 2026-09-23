# ---------------------------------------------------------
# RDS Instance
# ---------------------------------------------------------

output "db_instance_id" {
  description = "ID of the PostgreSQL RDS instance."
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "ARN of the PostgreSQL RDS instance."
  value       = aws_db_instance.this.arn
}


# ---------------------------------------------------------
# RDS Connection
# ---------------------------------------------------------

output "db_endpoint" {
  description = "Connection endpoint of the PostgreSQL RDS instance."
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port used by PostgreSQL."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Initial database created on the PostgreSQL RDS instance."
  value       = aws_db_instance.this.db_name
}

output "db_username" {
  description = "Master username of the PostgreSQL RDS instance."
  value       = aws_db_instance.this.username
  sensitive   = true
}


# ---------------------------------------------------------
# RDS Managed Master Secret
# ---------------------------------------------------------

output "master_user_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the RDS master credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}


# ---------------------------------------------------------
# RDS Subnet Group
# ---------------------------------------------------------

output "db_subnet_group_name" {
  description = "Name of the RDS DB subnet group."
  value       = aws_db_subnet_group.this.name
}
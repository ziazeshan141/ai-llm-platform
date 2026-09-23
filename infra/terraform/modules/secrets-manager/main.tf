# ---------------------------------------------------------
# Generate JWT Signing Secret
# ---------------------------------------------------------

resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}


# ---------------------------------------------------------
# Authentication Application Secret
# ---------------------------------------------------------

resource "aws_secretsmanager_secret" "auth" {
  name = "${var.project_name}/${var.environment}/auth"

  description = "Authentication secrets for ${var.project_name}"

  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = "${var.project_name}-${var.environment}-auth-secret"
  }
}


resource "aws_secretsmanager_secret_version" "auth" {
  secret_id = aws_secretsmanager_secret.auth.id

  secret_string = jsonencode({
    jwt_secret_key = random_password.jwt_secret.result
  })
}


# ---------------------------------------------------------
# Database Application Configuration
#
# IMPORTANT:
# The actual RDS password is NOT copied here.
# The credential remains in the RDS-managed Secrets Manager
# secret.
# ---------------------------------------------------------

resource "aws_secretsmanager_secret" "database_config" {
  name = "${var.project_name}/${var.environment}/database-config"

  description = "Database connection configuration for ${var.project_name}"

  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = "${var.project_name}-${var.environment}-database-config"
  }
}


resource "aws_secretsmanager_secret_version" "database_config" {
  secret_id = aws_secretsmanager_secret.database_config.id

  secret_string = jsonencode({
    host               = var.db_endpoint
    port               = var.db_port
    username           = var.db_username
    auth_database_name = var.auth_database_name
    rag_database_name  = var.rag_database_name
  })
}
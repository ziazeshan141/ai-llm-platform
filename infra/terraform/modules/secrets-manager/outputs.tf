# ---------------------------------------------------------
# Authentication Secret
# ---------------------------------------------------------

output "auth_secret_arn" {
  description = "ARN of the Secrets Manager secret containing authentication secrets."
  value       = aws_secretsmanager_secret.auth.arn
}

output "auth_secret_name" {
  description = "Name of the authentication secret."
  value       = aws_secretsmanager_secret.auth.name
}


# ---------------------------------------------------------
# Database Configuration Secret
# ---------------------------------------------------------

output "database_config_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database configuration."
  value       = aws_secretsmanager_secret.database_config.arn
}

output "database_config_secret_name" {
  description = "Name of the database configuration secret."
  value       = aws_secretsmanager_secret.database_config.name
}


# ---------------------------------------------------------
# Application Secret ARNs
# ---------------------------------------------------------

output "application_secret_arns" {
  description = "List of application Secrets Manager secret ARNs."

  value = [
    aws_secretsmanager_secret.auth.arn,
    aws_secretsmanager_secret.database_config.arn
  ]
}
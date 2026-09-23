# ---------------------------------------------------------
# General
# ---------------------------------------------------------

variable "project_name" {
  description = "Project name used for naming Secrets Manager secrets."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev or prod."
  type        = string
}


# ---------------------------------------------------------
# RDS Information
# ---------------------------------------------------------

variable "db_endpoint" {
  description = "RDS PostgreSQL endpoint used to construct application database URLs."
  type        = string
}

variable "db_port" {
  description = "PostgreSQL port."
  type        = number
  default     = 5432
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  sensitive   = true
}

variable "rds_master_secret_arn" {
  description = "ARN of the AWS-managed RDS master credential secret."
  type        = string
  sensitive   = true
}


# ---------------------------------------------------------
# Application Databases
# ---------------------------------------------------------

variable "auth_database_name" {
  description = "Database used by the authentication service."
  type        = string
  default     = "auth_db"
}

variable "rag_database_name" {
  description = "Database used by the RAG service."
  type        = string
  default     = "rag_db"
}


# ---------------------------------------------------------
# Secret Configuration
# ---------------------------------------------------------

variable "recovery_window_in_days" {
  description = "Number of days Secrets Manager waits before permanently deleting a secret."
  type        = number
  default     = 7

  validation {
    condition = (
      var.recovery_window_in_days == 0 ||
      (
        var.recovery_window_in_days >= 7 &&
        var.recovery_window_in_days <= 30
      )
    )

    error_message = "recovery_window_in_days must be 0 or between 7 and 30."
  }
}
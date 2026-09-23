# ---------------------------------------------------------
# General
# ---------------------------------------------------------

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev or prod."
  type        = string
}


# ---------------------------------------------------------
# Networking
# ---------------------------------------------------------

variable "database_subnet_ids" {
  description = "Private database subnet IDs where RDS will be deployed."
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID attached to the RDS PostgreSQL instance."
  type        = string
}


# ---------------------------------------------------------
# PostgreSQL
# ---------------------------------------------------------

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "database_name" {
  description = "Initial PostgreSQL database created by RDS."
  type        = string
}

variable "master_username" {
  description = "PostgreSQL master username."
  type        = string
}


# ---------------------------------------------------------
# Storage
# ---------------------------------------------------------

variable "allocated_storage" {
  description = "Initial allocated storage in GB."
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum storage in GB when RDS storage autoscaling is enabled."
  type        = number
}


# ---------------------------------------------------------
# Availability / Backup
# ---------------------------------------------------------

variable "multi_az" {
  description = "Whether RDS Multi-AZ deployment is enabled."
  type        = bool
}

variable "backup_retention_period" {
  description = "Number of days automated backups are retained."
  type        = number
}


# ---------------------------------------------------------
# Protection
# ---------------------------------------------------------

variable "deletion_protection" {
  description = "Protect the RDS instance from accidental deletion."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting RDS."
  type        = bool
  default     = true
}
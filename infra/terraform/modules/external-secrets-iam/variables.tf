# ---------------------------------------------------------
# General
# ---------------------------------------------------------

variable "project_name" {
  description = "Project name used for IAM resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev or prod."
  type        = string
}


# ---------------------------------------------------------
# Secrets Manager
# ---------------------------------------------------------

variable "secret_arns" {
  description = "Secrets Manager secret ARNs that External Secrets Operator can read."
  type        = list(string)
}


# ---------------------------------------------------------
# EKS Pod Identity
# ---------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where External Secrets Operator runs."
  type        = string
  default     = "external-secrets"
}

variable "service_account_name" {
  description = "Kubernetes service account used by External Secrets Operator."
  type        = string
  default     = "external-secrets"
}
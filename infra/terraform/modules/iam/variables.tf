variable "project_name" {
  description = "Project name used for IAM resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev or prod."
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID used when constructing IAM resource policies."
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "secrets_manager_secret_arns" {
  description = "Secrets Manager secret ARNs that External Secrets is allowed to read."
  type        = list(string)
  default     = []
}
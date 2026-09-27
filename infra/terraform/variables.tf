# ---------------------------------------------------------
# General
# ---------------------------------------------------------

variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for naming AWS resources."
  type        = string
  default     = "ai-llm-platform"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition = contains(
      ["dev", "staging", "prod"],
      var.environment
    )

    error_message = "Environment must be dev, staging, or prod."
  }
}


# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by the VPC."
  type        = list(string)

  default = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private EKS application subnets."
  type        = list(string)

  default = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"
  ]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for private RDS database subnets."
  type        = list(string)

  default = [
    "10.0.21.0/24",
    "10.0.22.0/24",
    "10.0.23.0/24"
  ]
}


# ---------------------------------------------------------
# ECR
# ---------------------------------------------------------

variable "ecr_repository_names" {
  description = "ECR repositories for application container images."
  type        = list(string)

  default = [
    "auth-service",
    "rag-service",
    "ai-service",
    "api-gateway",
    "frontend"
  ]
}


# ---------------------------------------------------------
# EKS
# ---------------------------------------------------------

variable "eks_cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "ai-llm-platform-dev-eks"
}

variable "eks_version" {
  description = "Kubernetes version used by the EKS cluster."
  type        = string
  default     = "1.35"
}

variable "eks_admin_principal_arn" {
  description = "IAM principal ARN granted administrator access to the EKS cluster."
  type        = string
}


# ---------------------------------------------------------
# EKS CPU Node Group
# ---------------------------------------------------------

variable "cpu_node_instance_types" {
  description = "EC2 instance types for the general EKS CPU node group."
  type        = list(string)

  default = [
    "t3.medium"
  ]
}

variable "cpu_node_desired_size" {
  description = "Desired number of CPU worker nodes."
  type        = number
  default     = 2
}

variable "cpu_node_min_size" {
  description = "Minimum number of CPU worker nodes."
  type        = number
  default     = 2
}

variable "cpu_node_max_size" {
  description = "Maximum number of CPU worker nodes."
  type        = number
  default     = 4
}


# ---------------------------------------------------------
# EKS GPU Node Group
# ---------------------------------------------------------

variable "gpu_node_instance_types" {
  description = "GPU EC2 instance types used for vLLM."
  type        = list(string)

  default = [
    "g4dn.xlarge"
  ]
}

variable "gpu_node_desired_size" {
  description = "Desired number of GPU worker nodes."
  type        = number
  default     = 1
}

variable "gpu_node_min_size" {
  description = "Minimum number of GPU worker nodes."
  type        = number
  default     = 0
}

variable "gpu_node_max_size" {
  description = "Maximum number of GPU worker nodes."
  type        = number
  default     = 1
}


# ---------------------------------------------------------
# RDS PostgreSQL
# ---------------------------------------------------------

variable "rds_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16"
}

variable "rds_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "rds_database_name" {
  description = "Initial PostgreSQL database."
  type        = string
  default     = "postgres"
}

variable "rds_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "ai_platform_admin"
}

variable "rds_allocated_storage" {
  description = "Initial RDS storage in GiB."
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum RDS storage autoscaling limit in GiB."
  type        = number
  default     = 100
}

variable "rds_multi_az" {
  description = "Whether RDS Multi-AZ is enabled."
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Number of days RDS automated backups are retained."
  type        = number
  default     = 7
}
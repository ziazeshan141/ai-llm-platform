# ---------------------------------------------------------
# General
# ---------------------------------------------------------

aws_region   = "us-east-1"
project_name = "ai-llm-platform"
environment  = "dev"


# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24",
  "10.0.3.0/24"
]

private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24",
  "10.0.13.0/24"
]

database_subnet_cidrs = [
  "10.0.21.0/24",
  "10.0.22.0/24",
  "10.0.23.0/24"
]


# ---------------------------------------------------------
# ECR
# ---------------------------------------------------------

ecr_repository_names = [
  "auth-service",
  "rag-service",
  "ai-service",
  "api-gateway",
  "frontend"
]


# ---------------------------------------------------------
# EKS
# ---------------------------------------------------------

eks_cluster_name = "ai-llm-platform-dev-eks"


# ---------------------------------------------------------
# CPU Node Group
# ---------------------------------------------------------

cpu_node_instance_types = [
  "t3.medium"
]

cpu_node_desired_size = 2
cpu_node_min_size     = 2
cpu_node_max_size     = 4


# ---------------------------------------------------------
# GPU Node Group
# ---------------------------------------------------------

gpu_node_instance_types = [
  "g4dn.xlarge"
]

gpu_node_desired_size = 1
gpu_node_min_size     = 0
gpu_node_max_size     = 1


# ---------------------------------------------------------
# RDS PostgreSQL
# ---------------------------------------------------------

rds_engine_version = "16"
rds_instance_class = "db.t3.micro"

rds_database_name = "postgres"
rds_username      = "ai_platform_admin"

rds_allocated_storage     = 20
rds_max_allocated_storage = 100

rds_multi_az                = false
rds_backup_retention_period = 7
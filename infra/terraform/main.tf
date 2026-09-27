# ---------------------------------------------------------
# Current AWS Account
# ---------------------------------------------------------

data "aws_caller_identity" "current" {}


# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment

  vpc_cidr = var.vpc_cidr

  availability_zones = var.availability_zones

  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
}


# ---------------------------------------------------------
# Security Groups
# ---------------------------------------------------------

module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment

  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr
}


# ---------------------------------------------------------
# ECR
# ---------------------------------------------------------

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment

  repository_names = var.ecr_repository_names

  image_tag_mutability = "IMMUTABLE"
  scan_on_push         = true
}


# ---------------------------------------------------------
# IAM
# ---------------------------------------------------------

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment

  aws_region     = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id

  eks_cluster_name = var.eks_cluster_name
}


# ---------------------------------------------------------
# EKS
# ---------------------------------------------------------

module "eks" {
  source = "./modules/eks"

  project_name = var.project_name
  environment  = var.environment

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_version

  private_subnet_ids = module.vpc.private_subnet_ids

  eks_workloads_security_group_id = (
    module.security_groups.eks_workloads_security_group_id
  )

  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  admin_principal_arn = var.eks_admin_principal_arn

  # CPU node group
  cpu_node_instance_types = var.cpu_node_instance_types
  cpu_node_desired_size   = var.cpu_node_desired_size
  cpu_node_min_size       = var.cpu_node_min_size
  cpu_node_max_size       = var.cpu_node_max_size

  # GPU node group
  gpu_node_instance_types = var.gpu_node_instance_types
  gpu_node_desired_size   = var.gpu_node_desired_size
  gpu_node_min_size       = var.gpu_node_min_size
  gpu_node_max_size       = var.gpu_node_max_size
}


# ---------------------------------------------------------
# RDS PostgreSQL
# ---------------------------------------------------------

module "rds" {
  source = "./modules/rds"

  project_name = var.project_name
  environment  = var.environment

  database_subnet_ids = module.vpc.database_subnet_ids

  rds_security_group_id = (
    module.security_groups.rds_security_group_id
  )

  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class

  database_name   = var.rds_database_name
  master_username = var.rds_username

  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage

  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period

  # Development settings.
  # We'll make these environment-driven before production.
  deletion_protection = false
  skip_final_snapshot = true
}


# ---------------------------------------------------------
# Application Secrets
# ---------------------------------------------------------

module "secrets_manager" {
  source = "./modules/secrets-manager"

  project_name = var.project_name
  environment  = var.environment

  db_endpoint = module.rds.db_endpoint
  db_port     = module.rds.db_port
  db_username = module.rds.db_username

  rds_master_secret_arn = module.rds.master_user_secret_arn

  auth_database_name = "auth_db"
  rag_database_name  = "rag_db"

  recovery_window_in_days = 7
}

# ---------------------------------------------------------
# External Secrets Operator IAM
# ---------------------------------------------------------

module "external_secrets_iam" {
  source = "./modules/external-secrets-iam"

  project_name = var.project_name
  environment  = var.environment

  cluster_name = module.eks.cluster_name

  namespace            = "external-secrets"
  service_account_name = "external-secrets"

  secret_arns = [
    module.rds.master_user_secret_arn,
    module.secrets_manager.auth_secret_arn,
    module.secrets_manager.database_config_secret_arn
  ]
}
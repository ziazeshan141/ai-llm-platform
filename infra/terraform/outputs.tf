# ---------------------------------------------------------
# VPC
# ---------------------------------------------------------

output "vpc_id" {
  description = "ID of the project VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private EKS subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Private database subnet IDs."
  value       = module.vpc.database_subnet_ids
}


# ---------------------------------------------------------
# ECR
# ---------------------------------------------------------

output "ecr_repository_urls" {
  description = "ECR repository URLs for application services."
  value       = module.ecr.repository_urls
}


# ---------------------------------------------------------
# EKS
# ---------------------------------------------------------

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Kubernetes API endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group created by EKS for the cluster."
  value       = module.eks.cluster_security_group_id
}

output "eks_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster."
  value       = module.eks.cluster_oidc_issuer_url
}

output "cpu_node_group_name" {
  description = "CPU managed node group name."
  value       = module.eks.cpu_node_group_name
}

output "gpu_node_group_name" {
  description = "GPU managed node group name."
  value       = module.eks.gpu_node_group_name
}


# ---------------------------------------------------------
# RDS
# ---------------------------------------------------------

output "rds_endpoint" {
  description = "PostgreSQL RDS endpoint."
  value       = module.rds.db_endpoint
}

output "rds_port" {
  description = "PostgreSQL RDS port."
  value       = module.rds.db_port
}

output "rds_master_secret_arn" {
  description = "AWS-managed Secrets Manager secret for RDS master credentials."
  value       = module.rds.master_user_secret_arn
  sensitive   = true
}


# ---------------------------------------------------------
# Application Secrets
# ---------------------------------------------------------

output "auth_secret_arn" {
  description = "Secrets Manager ARN containing authentication secrets."
  value       = module.secrets_manager.auth_secret_arn
}

output "database_config_secret_arn" {
  description = "Secrets Manager ARN containing application database configuration."
  value       = module.secrets_manager.database_config_secret_arn
}

# ---------------------------------------------------------
# External Secrets
# ---------------------------------------------------------

output "external_secrets_role_arn" {
  description = "IAM role ARN used by External Secrets Operator."
  value       = module.external_secrets_iam.role_arn
}

output "external_secrets_policy_arn" {
  description = "IAM policy ARN used by External Secrets Operator."
  value       = module.external_secrets_iam.policy_arn
}

output "external_secrets_pod_identity_association_id" {
  description = "EKS Pod Identity association ID for External Secrets Operator."
  value       = module.external_secrets_iam.pod_identity_association_id
}
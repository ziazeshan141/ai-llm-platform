output "eks_workloads_security_group_id" {
  description = "Security group ID used by EKS CPU and GPU worker nodes."
  value       = aws_security_group.eks_workloads.id
}

output "rds_security_group_id" {
  description = "Security group ID used by the RDS PostgreSQL instance."
  value       = aws_security_group.rds.id
}
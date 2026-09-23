# ---------------------------------------------------------
# EKS Cluster Role
# ---------------------------------------------------------

output "eks_cluster_role_arn" {
  description = "ARN of the IAM role used by the EKS control plane."
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description = "Name of the IAM role used by the EKS control plane."
  value       = aws_iam_role.eks_cluster.name
}


# ---------------------------------------------------------
# EKS Node Role
# ---------------------------------------------------------

output "eks_node_role_arn" {
  description = "ARN of the IAM role used by EKS managed node groups."
  value       = aws_iam_role.eks_node.arn
}

output "eks_node_role_name" {
  description = "Name of the IAM role used by EKS managed node groups."
  value       = aws_iam_role.eks_node.name
}
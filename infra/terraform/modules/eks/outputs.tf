# ---------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------

output "cluster_id" {
  description = "Name/ID of the EKS cluster."
  value       = aws_eks_cluster.this.id
}

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS cluster."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster."
  value       = aws_eks_cluster.this.version
}


# ---------------------------------------------------------
# Cluster Certificate
# ---------------------------------------------------------

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the EKS cluster."
  value = try(
    aws_eks_cluster.this.certificate_authority[0].data,
    null
  )
}


# ---------------------------------------------------------
# Cluster Security Group
# ---------------------------------------------------------

output "cluster_security_group_id" {
  description = "Security group created by EKS for the cluster."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}


# ---------------------------------------------------------
# OIDC
# ---------------------------------------------------------

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster."
  value = try(
    aws_eks_cluster.this.identity[0].oidc[0].issuer,
    null
  )
}


# ---------------------------------------------------------
# CPU Managed Node Group
# ---------------------------------------------------------

output "cpu_node_group_name" {
  description = "Name of the CPU EKS managed node group."
  value       = aws_eks_node_group.cpu.node_group_name
}

output "cpu_node_group_arn" {
  description = "ARN of the CPU EKS managed node group."
  value       = aws_eks_node_group.cpu.arn
}


# ---------------------------------------------------------
# GPU Managed Node Group
# ---------------------------------------------------------

output "gpu_node_group_name" {
  description = "Name of the GPU EKS managed node group."
  value       = aws_eks_node_group.gpu.node_group_name
}

output "gpu_node_group_arn" {
  description = "ARN of the GPU EKS managed node group."
  value       = aws_eks_node_group.gpu.arn
}

# ---------------------------------------------------------
# EKS Pod Identity Agent
# ---------------------------------------------------------

output "pod_identity_agent_addon_arn" {
  description = "ARN of the EKS Pod Identity Agent add-on."
  value       = aws_eks_addon.pod_identity_agent.arn
}
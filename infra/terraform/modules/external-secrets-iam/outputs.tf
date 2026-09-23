# ---------------------------------------------------------
# External Secrets IAM Role
# ---------------------------------------------------------

output "role_arn" {
  description = "ARN of the IAM role used by External Secrets Operator through EKS Pod Identity."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role used by External Secrets Operator."
  value       = aws_iam_role.this.name
}


# ---------------------------------------------------------
# External Secrets IAM Policy
# ---------------------------------------------------------

output "policy_arn" {
  description = "ARN of the IAM policy allowing External Secrets Operator to read application secrets."
  value       = aws_iam_policy.this.arn
}


# ---------------------------------------------------------
# EKS Pod Identity Association
# ---------------------------------------------------------

output "pod_identity_association_id" {
  description = "ID of the EKS Pod Identity association for External Secrets Operator."
  value       = aws_eks_pod_identity_association.this.association_id
}
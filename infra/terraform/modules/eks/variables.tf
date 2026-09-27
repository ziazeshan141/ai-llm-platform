# ---------------------------------------------------------
# General
# ---------------------------------------------------------

variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
}

variable "environment" {
  description = "Deployment environment such as dev or prod."
  type        = string
}


# ---------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version used by the EKS cluster."
  type        = string
}


# ---------------------------------------------------------
# Networking
# ---------------------------------------------------------

variable "private_subnet_ids" {
  description = "Private subnet IDs where EKS managed nodes will run."
  type        = list(string)
}

variable "eks_workloads_security_group_id" {
  description = "Security group ID used by EKS worker nodes."
  type        = string
}


# ---------------------------------------------------------
# IAM
# ---------------------------------------------------------

variable "cluster_role_arn" {
  description = "IAM role ARN used by the EKS control plane."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN used by EKS managed node groups."
  type        = string
}

variable "admin_principal_arn" {
  description = "IAM principal ARN granted administrator access to the EKS cluster."
  type        = string
}


# ---------------------------------------------------------
# CPU Managed Node Group
# ---------------------------------------------------------

variable "cpu_node_instance_types" {
  description = "EC2 instance types used by the CPU managed node group."
  type        = list(string)
}

variable "cpu_node_desired_size" {
  description = "Desired number of CPU worker nodes."
  type        = number
}

variable "cpu_node_min_size" {
  description = "Minimum number of CPU worker nodes."
  type        = number
}

variable "cpu_node_max_size" {
  description = "Maximum number of CPU worker nodes."
  type        = number
}


# ---------------------------------------------------------
# GPU Managed Node Group
# ---------------------------------------------------------

variable "gpu_node_instance_types" {
  description = "GPU EC2 instance types used by the vLLM node group."
  type        = list(string)
}

variable "gpu_node_desired_size" {
  description = "Desired number of GPU worker nodes."
  type        = number
}

variable "gpu_node_min_size" {
  description = "Minimum number of GPU worker nodes."
  type        = number
}

variable "gpu_node_max_size" {
  description = "Maximum number of GPU worker nodes."
  type        = number
}
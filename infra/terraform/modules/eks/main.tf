# ---------------------------------------------------------
# EKS Cluster
# ---------------------------------------------------------

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.private_subnet_ids

    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  tags = {
    Name = var.cluster_name
  }
}

# ---------------------------------------------------------
# EKS Administrator Access
# ---------------------------------------------------------

resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.admin_principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = aws_eks_access_entry.admin.principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.admin
  ]
}

# ---------------------------------------------------------
# CPU Node Launch Template
# ---------------------------------------------------------

resource "aws_launch_template" "cpu" {
  name_prefix = "${var.project_name}-${var.environment}-cpu-"

  vpc_security_group_ids = [
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
    var.eks_workloads_security_group_id
  ]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name     = "${var.project_name}-${var.environment}-cpu-node"
      NodeType = "cpu"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


# ---------------------------------------------------------
# GPU Node Launch Template
# ---------------------------------------------------------

resource "aws_launch_template" "gpu" {
  name_prefix = "${var.project_name}-${var.environment}-gpu-"

  vpc_security_group_ids = [
    aws_eks_cluster.this.vpc_config[0].cluster_security_group_id,
    var.eks_workloads_security_group_id
  ]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name     = "${var.project_name}-${var.environment}-gpu-node"
      NodeType = "gpu"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


# ---------------------------------------------------------
# CPU Managed Node Group
# ---------------------------------------------------------

resource "aws_eks_node_group" "cpu" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-${var.environment}-cpu"
  node_role_arn   = var.node_role_arn

  subnet_ids = var.private_subnet_ids

  instance_types = var.cpu_node_instance_types

  ami_type = "AL2023_x86_64_STANDARD"

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = var.cpu_node_desired_size
    min_size     = var.cpu_node_min_size
    max_size     = var.cpu_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.cpu.id
    version = aws_launch_template.cpu.latest_version
  }

  labels = {
    workload  = "general"
    node-type = "cpu"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cpu-node-group"
  }

  depends_on = [
    aws_eks_cluster.this
  ]
}


# ---------------------------------------------------------
# GPU Managed Node Group
# ---------------------------------------------------------

resource "aws_eks_node_group" "gpu" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-${var.environment}-gpu"
  node_role_arn   = var.node_role_arn

  subnet_ids = var.private_subnet_ids

  instance_types = var.gpu_node_instance_types

  ami_type = "AL2023_x86_64_NVIDIA"

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = var.gpu_node_desired_size
    min_size     = var.gpu_node_min_size
    max_size     = var.gpu_node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  launch_template {
    id      = aws_launch_template.gpu.id
    version = aws_launch_template.gpu.latest_version
  }

  labels = {
    workload  = "gpu"
    node-type = "gpu"
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-gpu-node-group"
  }

  depends_on = [
    aws_eks_cluster.this
  ]
}

# ---------------------------------------------------------
# EKS Pod Identity Agent
# ---------------------------------------------------------

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.this.name
  addon_name   = "eks-pod-identity-agent"

  tags = {
    Name = "${var.project_name}-${var.environment}-pod-identity-agent"
  }

  depends_on = [
    aws_eks_node_group.cpu,
    aws_eks_node_group.gpu
  ]
}
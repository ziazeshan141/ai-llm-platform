# ---------------------------------------------------------
# EKS Workload Security Group
# ---------------------------------------------------------

resource "aws_security_group" "eks_workloads" {
  name        = "${var.project_name}-${var.environment}-eks-workloads-sg"
  description = "Security group for EKS worker nodes and workloads"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-workloads-sg"
  }
}


# ---------------------------------------------------------
# EKS Workload Egress
# ---------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "eks_all_egress" {
  security_group_id = aws_security_group.eks_workloads.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic from EKS workloads"
}


# ---------------------------------------------------------
# EKS Workload Internal Communication
# ---------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "eks_internal" {
  security_group_id = aws_security_group.eks_workloads.id

  referenced_security_group_id = aws_security_group.eks_workloads.id

  ip_protocol = "-1"

  description = "Allow communication between EKS workloads"
}


# ---------------------------------------------------------
# RDS Security Group
# ---------------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for PostgreSQL RDS"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}


# ---------------------------------------------------------
# PostgreSQL Access
# EKS -> RDS
# ---------------------------------------------------------

resource "aws_vpc_security_group_ingress_rule" "rds_postgres_from_eks" {
  security_group_id = aws_security_group.rds.id

  referenced_security_group_id = aws_security_group.eks_workloads.id

  from_port   = 5432
  to_port     = 5432
  ip_protocol = "tcp"

  description = "Allow PostgreSQL access from EKS workloads"
}


# ---------------------------------------------------------
# RDS Egress
# ---------------------------------------------------------

resource "aws_vpc_security_group_egress_rule" "rds_all_egress" {
  security_group_id = aws_security_group.rds.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic from RDS"
}
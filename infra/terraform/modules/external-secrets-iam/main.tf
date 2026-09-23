# ---------------------------------------------------------
# External Secrets - Pod Identity Trust Policy
# ---------------------------------------------------------

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}


# ---------------------------------------------------------
# External Secrets - IAM Role
# ---------------------------------------------------------

resource "aws_iam_role" "this" {
  name = "${var.project_name}-${var.environment}-external-secrets-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = "${var.project_name}-${var.environment}-external-secrets-role"
  }
}


# ---------------------------------------------------------
# Secrets Manager Read Policy
# ---------------------------------------------------------

data "aws_iam_policy_document" "secrets_manager" {
  statement {
    sid    = "ReadApplicationSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = var.secret_arns
  }
}


resource "aws_iam_policy" "this" {
  name = "${var.project_name}-${var.environment}-external-secrets-policy"

  description = "Allows External Secrets Operator to read application secrets"

  policy = data.aws_iam_policy_document.secrets_manager.json

  tags = {
    Name = "${var.project_name}-${var.environment}-external-secrets-policy"
  }
}


# ---------------------------------------------------------
# Attach Policy to Pod Identity Role
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}


# ---------------------------------------------------------
# EKS Pod Identity Association
# ---------------------------------------------------------

resource "aws_eks_pod_identity_association" "this" {
  cluster_name = var.cluster_name

  namespace = var.namespace

  service_account = var.service_account_name

  role_arn = aws_iam_role.this.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-external-secrets"
  }

  depends_on = [
    aws_iam_role_policy_attachment.this
  ]
}
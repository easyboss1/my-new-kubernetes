# ------------------------------------------------------------------------------
# IAM Role for EKS Control Plane
# This role is assumed by the EKS service to manage the control plane resources
# ------------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster" {
  # Unique name for the control plane IAM role
  name = "${local.name}-tesco_eks-cluster-role"

  # Trust policy to allow EKS to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  # Tags applied to this IAM role
  tags = var.tags
}

# ------------------------------------------------------------------------------
# Attach the required policy for EKS to manage cluster control plane
# This is mandatory for all EKS clusters
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ------------------------------------------------------------------------------
# Attach VPC Resource Controller policy
# Required for advanced networking, Fargate, and Karpenter support
# Recommended to include by default for production-grade EKS
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.eks_admin_principal_arn
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = var.eks_admin_principal_arn

  # AWS-managed EKS admin policy
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
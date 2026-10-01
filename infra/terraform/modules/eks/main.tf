# EKS cluster + one managed node group.
# COST: the EKS control plane is billed per hour even with zero pods, plus the
# nodes and the NAT gateway. Always `terraform destroy` when you're done.
#
# TODO(stage 4) - things to work through and understand, not just copy:
#   [ ] Why do nodes live in private subnets?
#   [ ] What does `enable_cluster_creator_admin_permissions` do, and how would
#       you give your colleague (or CI) access via `access_entries` instead?
#   [ ] Install the AWS Load Balancer Controller (Helm) so the Ingress gets an
#       ALB - needs an IAM role for its service account (IRSA or Pod Identity).
#   [ ] Spot vs on-demand nodes: when is spot a good idea?

variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "kubernetes_version" {
  type    = string
  default = "1.31" # TODO: check the current supported EKS versions
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.name
  cluster_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Lets you run kubectl from your laptop. Tighten for anything real.
  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      capacity_type  = "SPOT" # much cheaper; nodes can be reclaimed
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}

output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "node_security_group_id" { value = module.eks.node_security_group_id }
output "oidc_provider_arn" { value = module.eks.oidc_provider_arn }

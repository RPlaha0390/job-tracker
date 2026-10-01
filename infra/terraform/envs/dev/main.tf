# Stage 4: the dev environment. Apply in pieces while learning:
#   terraform init
#   terraform apply -target=module.network -target=module.ecr   # cheap-ish
#   terraform apply                                              # adds EKS (costs!)
#   terraform destroy                                            # when done for the day

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "github_repo" {
  type        = string
  description = "owner/repo allowed to deploy, e.g. raman/job-tracker"
}

locals {
  name = "job-tracker-dev"
}

module "network" {
  source = "../../modules/network"
  name   = local.name
}

module "ecr" {
  source       = "../../modules/ecr"
  repositories = ["job-tracker-api", "job-tracker-web"]
}

module "eks" {
  source     = "../../modules/eks"
  name       = local.name
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids
}

# TODO(stage 4): uncomment once you've written modules/rds
# module "rds" {
#   source                    = "../../modules/rds"
#   name                      = local.name
#   vpc_id                    = module.network.vpc_id
#   subnet_ids                = module.network.private_subnet_ids
#   allowed_security_group_id = module.eks.node_security_group_id
# }

output "ecr_repository_urls" { value = module.ecr.repository_urls }
output "cluster_name" { value = module.eks.cluster_name }
output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

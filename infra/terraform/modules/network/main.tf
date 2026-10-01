# VPC with public subnets (load balancer) and private subnets (nodes, RDS)
# across 2 availability zones. Uses the community module rather than writing
# ~20 resources by hand.
# TODO(stage 4): read the module's generated plan. Can you explain what a NAT
# gateway is and why private subnets need one? (It's also the main idle cost.)

variable "name" { type = string }
variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr
  azs  = local.azs

  public_subnets  = [for i, _ in local.azs : cidrsubnet(var.cidr, 8, i)]
  private_subnets = [for i, _ in local.azs : cidrsubnet(var.cidr, 8, i + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true # cheaper; one per AZ is the resilient prod choice

  # Tags the AWS Load Balancer Controller uses to find subnets.
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }
}

output "vpc_id" { value = module.vpc.vpc_id }
output "private_subnet_ids" { value = module.vpc.private_subnets }
output "public_subnet_ids" { value = module.vpc.public_subnets }
output "vpc_cidr" { value = var.cidr }

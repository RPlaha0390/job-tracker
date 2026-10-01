# Managed Postgres (RDS). This one is deliberately left for YOU to write -
# it's the best Terraform exercise in the project.
#
# TODO(stage 4): implement, roughly in this order:
#   [ ] aws_db_subnet_group using var.subnet_ids (private subnets)
#   [ ] aws_security_group allowing 5432 ONLY from var.allowed_security_group_id
#       (the EKS node SG) - not from 0.0.0.0/0
#   [ ] aws_db_instance:
#         engine = "postgres", engine_version = "16", instance_class = "db.t4g.micro"
#         allocated_storage = 20, db_name = "tracker", username = "tracker"
#         manage_master_user_password = true   <- AWS generates + stores it in
#                                                  Secrets Manager for you
#         skip_final_snapshot = true, deletion_protection = false  (dev only!)
#         publicly_accessible = false
#   [ ] outputs: endpoint, and the Secrets Manager secret ARN
#       (aws_db_instance.this.master_user_secret[0].secret_arn)
#
# Then, in docs/decisions.md: why RDS instead of the Postgres StatefulSet you
# ran on kind? (backups, failover, patching, storage...) And what would
# multi_az = true buy you, at what cost?

variable "name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "allowed_security_group_id" { type = string }

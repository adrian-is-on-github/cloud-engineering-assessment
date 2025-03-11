data "aws_caller_identity" "current" {}

module "vpc" {
  source             = "./modules/vpc"
  availability_zones = ["a", "b"]
  nat_enabled        = var.nat_enabled
  vpc_cidr           = "172.100.0.0/16"
  wireguard_ports    = var.wireguard_ports
  vpn_ips            = var.vpn_ips
  tags               = var.tags
}




# ### RDS Instances (when and if needed) ###
# module "rds-instance-us-east-1" {
#   providers = { aws = aws.nvirginia }
#   source    = "./modules/rds"
#   enable_db = var.enable_db_nvirginia

#   allocated_storage         = var.rds["nvirginia"].allocated_storage
#   availability_zones        = ["us-east-1a", "us-east-1b"]
#   bucket_name               = module.s3-bucket-rds-backup-us-east-1.bucket_name
#   db_parameter_group_family = var.rds["nvirginia"].db_parameter_group_family
#   db_security_group_ids     = module.vpc-us-east-1.db_security_group_ids
#   enable_option_group       = true
#   engine                    = var.rds["nvirginia"].engine
#   engine_version            = var.rds["nvirginia"].engine_version
#   instance_class            = var.rds["nvirginia"].instance_class
#   kms_key_id                = module.s3-bucket-rds-backup-us-east-1.kms_key_id
#   master_password           = var.master_password_us_east_1
#   subnet_ids                = module.vpc-us-east-1.db_subnet_ids

#   tags = var.tags
# }



output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
data "aws_caller_identity" "current" {}

module "vpc" {
  providers          = { aws = aws.ireland }
  source             = "./modules/vpc"
  availability_zones = ["a", "b"]
  nat_enabled        = var.nat_enabled
  vpc_cidr           = "172.100.0.0/16"
  open_public_ports  = ["5000", "5000"]
  tags               = var.tags
}



module "flask_app_ecr" {
  providers            = { aws = aws.ireland }
  source               = "./modules/ecr"
  ecr_repo_name        = "flask_app"
  image_tag_mutability = "MUTABLE"
  expiration_days      = 30
  tags                 = var.tags
}



module "flask_app_cluster" {
  providers = { aws = aws.ireland }
  source    = "./modules/ecs"

  app_ecr_repo_url = module.flask_app_ecr.ecr_repo_url
  cluster_name     = "flask_app_cluster"

  service_name                   = "flask_app_service"
  subnet_ids                     = module.vpc.public_subnet_ids # Using public subnets - could do private subnets and put a load balancer in front
  task_definition_family         = "flask_app_task_definition"
  task_definition_cpu            = "256"
  task_definition_memory         = "512"
  task_definition_container_port = 5000
  task_definition_host_port      = 5000

  tags = var.tags
}



# ### RDS Instance(s) (when and if needed) ###
# module "rds-instance-us-east-1" {
#   providers = { aws = aws.nvirginia }
#   source    = "./modules/rds"
#   enable_db = var.enable_db_nvirginia # Simple count parameter to create/skip creation of the RDS instance

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

#################
### VARIABLES ###
#################
# variable "db_enabled" {
#   description = "Enable RDS instance"
#   type        = bool
#   default     = false
# }
# variable "db_master_password" {
#   description = "Master password for RDS instance"
#   type        = string
# }
# variable "db_rds_config" {
#   description = "RDS configuration"
#   type        = any
# }
variable "nat_enabled" {
  description = "Enable NAT gateway and private subnet route table associations"
  type        = bool
  default     = false
}



# Common #
variable "random_seed" {
  description = "Random characters for unique resource names"
  type        = string
  default     = "lwepfnay"
}

variable "tags" {
  description = "Standard tags for resources"
  type        = map(string)
  default = { "Managed by Terraform" = "true",
  "Project" = "cloud_engineering_assessment" }
}
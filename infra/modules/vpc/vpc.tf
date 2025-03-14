# AWS defined here to clear the implied provider error message
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

############
### DATA ###
############
data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}


### VARIABLES ###
variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}
variable "nat_enabled" {
  description = "Enable NAT gateway"
  type        = bool
}
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}
variable "open_public_ports" {
  description = "List of wireguard ports"
  type        = list(number)
}
variable "tags" {
  description = "Standard tags for resources"
  type        = map(string)
}


##############
### LOCALS ###
##############
# Create cidr blocks for subnets
locals {
  base_cidr = var.vpc_cidr
  public_subnets = [
    cidrsubnet(local.base_cidr, 4, 0), # 172.xxx.0.0/20
    cidrsubnet(local.base_cidr, 4, 1)  # 172.xxx.16.0/20
  ]
  private_subnets = [
    cidrsubnet(local.base_cidr, 4, 2), # 172.xxx.32.0/20
    cidrsubnet(local.base_cidr, 4, 3)  # 172.xxx.48.0/20
  ]
  db_subnets = [
    cidrsubnet(local.base_cidr, 4, 4), # 172.xxx.64.0/20
    cidrsubnet(local.base_cidr, 4, 5)  # 172.xxx.80.0/20
  ]
}



#################
### RESOURCES ###
#################
### VPC ###
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "vpc-${data.aws_region.current.name}"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {
  count  = var.nat_enabled ? 1 : 0 # Only create if NAT is enabled
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  count         = var.nat_enabled ? 1 : 0 # Only create if NAT is enabled
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  tags = merge(var.tags, {
    type = "s3_vpc_endpoint"
  })
}



### SUBNETS ###
resource "aws_subnet" "public" {
  count                   = length(local.public_subnets)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnets[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}" # Auto name it based on the AZ
  }
}
resource "aws_subnet" "private" {
  count             = length(local.private_subnets)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnets[count.index]

  tags = {
    Name = "private-subnet-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}" # Auto name it based on the AZ
  }
}
resource "aws_subnet" "db" {
  count             = length(local.db_subnets)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.db_subnets[count.index]

  tags = {
    Name = "db-subnet-${substr(data.aws_availability_zones.available.names[count.index], -1, 1)}" # Auto name it based on the AZ
  }
}



### ROUTE TABLE ###
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge(var.tags, {
    Name = "public-route-table"
  })
}

resource "aws_route_table" "private" {
  count  = var.nat_enabled ? 1 : 0 # Only create if NAT is enabled
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  tags = merge(var.tags, {
    Name = "private-route-table"
  })
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "db-route-table"
  })
}



# ROUTE TABLE ASSOCIATIONS #
resource "aws_route_table_association" "public" {
  for_each       = { for index, subnet in local.public_subnets : index => subnet } # Create a map of the subnets with an index ID
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  for_each       = var.nat_enabled ? { for index, subnet in local.private_subnets : index => subnet } : {} # Only create if NAT is enabled, and create a map of the subnets with an index ID
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[0].id
}
resource "aws_route_table_association" "db" {
  for_each       = { for index, subnet in local.db_subnets : index => subnet } # Create a map of the subnets with an index ID
  subnet_id      = aws_subnet.db[each.key].id
  route_table_id = aws_route_table.db.id
}
# S3 VPC ENDPOINT ROUTE TABLE ASSOCIATION
resource "aws_vpc_endpoint_route_table_association" "s3-endpoint" {
  route_table_id  = aws_route_table.db.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}



### NACL ###
resource "aws_network_acl" "public-nacl" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  # Allow inbound traffic
  ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  # Allow all outbound traffic
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = merge(var.tags, {
    Name = "public-subnet-nacl"
  })
  ########### Future Improvement #########
  # More refined ingress and egress rules
  ########################################
}



### SECURITY GROUPS ###
resource "aws_security_group" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name        = "public-sg-${data.aws_region.current.name}",
    Description = "public-sg-${data.aws_region.current.name}"
  })
}
resource "aws_vpc_security_group_ingress_rule" "open_public_ports" {
  security_group_id = aws_security_group.public.id
  from_port         = var.open_public_ports[0]
  to_port           = var.open_public_ports[1]
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_vpc_security_group_egress_rule" "all_outbound_pub" {
  security_group_id = aws_security_group.public.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}


### DB SECURITY GROUP ###
resource "aws_security_group" "db" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name        = "db-sg-${data.aws_region.current.name}",
    Description = "db-sg-${data.aws_region.current.name}"
  })
}
resource "aws_vpc_security_group_ingress_rule" "rds_ingress" {
  security_group_id = aws_security_group.db.id
  from_port         = 1433
  to_port           = 1433
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}
resource "aws_vpc_security_group_egress_rule" "all_outbound_db" {
  security_group_id = aws_security_group.db.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}



###############
### OUTPUTS ###
###############
output "db_security_group_ids" {
  value = [aws_security_group.db.id]
}
output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}
output "public_security_group_ids" {
  value = [aws_security_group.public.id]
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
# output "private_security_group_ids"{ 
#   value = [aws_security_group.private.id]
# }
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
# When using load balancer and deploying app in private subnet
# output "private_security_group_ids" {
#   value = [aws_security_group.private.id]
# }
output "vpc_id" {
  value = aws_vpc.main.id
}

# -------------------------------------------------------------------------------------
#
# Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
#
# This software is the property of WSO2 LLC. and its suppliers, if any.
# Dissemination of any information or reproduction of any material contained
# herein in any form is strictly forbidden, unless permitted by WSO2 expressly.
# You may not alter or remove any copyright or other notice from copies of this content.
#
# --------------------------------------------------------------------------------------

module "vpc" {
  source               = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/VPC?ref=v1.12.0"
  project              = var.project
  environment          = var.environment_name
  region               = var.region
  application          = var.client_name
  enable_dns_hostnames = true
  vpc_cidr_block       = var.vpc_cidr_block
  tags                 = var.default_tags
}

module "internet_gateway" {
  source      = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/Gateway?ref=v1.12.0"
  project     = var.project
  environment = var.environment_name
  region      = var.region
  application = var.client_name
  tags        = var.default_tags
  vpc_ids     = [module.vpc.vpc_id]

  depends_on = [
    module.vpc
  ]
}

module "nat_gateway_subnet" {
  source            = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/VPC-Subnet?ref=v1.12.0"
  project           = var.project
  environment       = var.environment_name
  region            = var.region
  application       = join("-", [var.client_name, "dmz"])
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = var.az_dmz_subnet_cidr_block
  vpc_id            = module.vpc.vpc_id
  custom_routes     = []
  tags              = merge(var.default_tags, { "kubernetes.io/role/elb" : 1 })
}

module "nat_gateway_subnet_routes" {
  source         = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/VPC-Subnet-Routes?ref=v1.12.0"
  route_table_id = module.nat_gateway_subnet.route_table_id
  routes = [
    {
      "cidr_block" = "0.0.0.0/0"
      "ep_type"    = "gateway_id"
      "ep_id"      = module.internet_gateway.gateway_id
    }
  ]
  depends_on = [
    module.internet_gateway
  ]
}

module "nat_gateway" {
  source      = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/NAT-Gateway?ref=v1.12.0"
  project     = var.project
  environment = var.environment_name
  region      = var.region
  application = var.client_name
  tags        = var.default_tags
  subnet_id   = module.nat_gateway_subnet.subnet_id

  depends_on = [
    module.internet_gateway
  ]
}

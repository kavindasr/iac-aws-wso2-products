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

module "eks_cluster" {
  source                    = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/EKS-Cluster?ref=v1.12.0"
  project                   = var.project
  environment               = var.environment_name
  region                    = var.region
  application               = var.client_name
  tags                      = var.default_tags
  eks_vpc_id                = module.vpc.vpc_id
  kubernetes_version        = var.kubernetes_version
  service_ipv4_cidr         = var.eks_service_ipv4_cidr
  enabled_cluster_log_types = ["audit", "controllerManager", "scheduler"]
  subnet_details = [
    {
      "availability_zone" : data.aws_availability_zones.available.names[0]
      "cidr_block" : var.eks_availability_zone_1_subnet_cidr_block
      "custom_routes" : [
        {
          "cidr_block" = "0.0.0.0/0"
          "ep_type"    = "nat_gateway_id"
          "ep_id"      = module.nat_gateway.nat_gateway_id
        }
      ]
    },
    {
      "availability_zone" : data.aws_availability_zones.available.names[1]
      "cidr_block" : var.eks_availability_zone_2_subnet_cidr_block
      "custom_routes" : [
        {
          "cidr_block" = "0.0.0.0/0"
          "ep_type"    = "nat_gateway_id"
          "ep_id"      = module.nat_gateway.nat_gateway_id
        }
      ]
    }
  ]
}

module "eks_cluster_node_group" {
  source           = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/EKS-Node-Group?ref=v1.12.0"
  eks_cluster_name = module.eks_cluster.eks_cluster_name
  node_group_name  = "np"
  subnet_ids       = module.eks_cluster.eks_subnet_ids
  desired_size     = var.eks_default_nodepool_desired_size
  max_size         = var.eks_default_nodepool_max_size
  min_size         = var.eks_default_nodepool_min_size
  k8s_version      = var.kubernetes_version
  max_unavailable  = var.eks_default_nodepool_max_unavailable
  tags             = var.default_tags
  instance_types   = var.eks_instance_types
  depends_on = [
    module.eks_cluster
  ]
}

module "eks_cluster_bastion_access_sg_rule" {
  source            = "git::https://github.com/wso2/aws-terraform-modules.git//modules/aws/Security-Group-Rule?ref=v1.12.0"
  security_group_id = module.eks_cluster.eks_security_group_rule_id
  rules = [
    {
      "direction" : "ingress"
      "from_port" : 6443
      "to_port" : 6443
      "protocol" : "TCP"
      "cidr_blocks" : [var.bastion_cidr_block]
      "security_groups" : []
    },
    {
      "direction" : "ingress"
      "from_port" : 443
      "to_port" : 443
      "protocol" : "TCP"
      "cidr_blocks" : [var.bastion_cidr_block]
      "security_groups" : []
    }
  ]
}

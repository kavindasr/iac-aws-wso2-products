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


output "database_writer_endpoint" {
  description = "Writer endpoint of the database instance."
  value       = length(module.aurora_mysql_rds_cluster) > 0 ? module.aurora_mysql_rds_cluster[0].database_writer_endpoint : null
  depends_on  = [module.aurora_mysql_rds_cluster]
}

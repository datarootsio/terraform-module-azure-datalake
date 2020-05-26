output "name" {
  value = var.data_lake_name
}

output "powerbi_sql_dw_server_hostname" {
  value = contains(azurerm_sql_server.synapse_srv, 0) ? azurerm_sql_server.synapse_srv[0].fully_qualified_domain_name : ""
}

output "powerbi_sql_dw_server_database" {
  value = contains(azurerm_sql_database.synapse, 0) ? azurerm_sql_database.synapse[0].name : ""
}

output "powerbi_sql_dw_server_user" {
  value = local.powerbi_viewer_user
}

output "powerbi_sql_dw_server_password" {
  value = contains(random_password.sql_powerbi_viewer, 0) ? random_password.sql_powerbi_viewer[0].result : ""
}
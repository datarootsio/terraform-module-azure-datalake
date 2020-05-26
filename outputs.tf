output "name" {
  value = var.data_lake_name
}

output "powerbi_sql_dw_server_hostname" {
  value = azurerm_sql_server.synapse_srv[local.create_synapse].fully_qualified_domain_name
}

output "powerbi_sql_dw_server_database" {
  value = azurerm_sql_database.synapse[local.create_synapse].name
}

output "powerbi_sql_dw_server_user" {
  value = local.powerbi_viewer_user
}

output "powerbi_sql_dw_server_password" {
  value = random_password.sql_powerbi_viewer[local.create_synapse].result
}
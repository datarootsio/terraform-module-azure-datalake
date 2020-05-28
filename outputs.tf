output "name" {
  description = "Name of the data lake"
  value       = var.data_lake_name
}

output "powerbi_sql_dw_server_hostname" {
  description = "Name of the SQL server that hosts the Azure Synapse Analytics instance"
  value       = contains(azurerm_sql_server.synapse_srv, 0) ? azurerm_sql_server.synapse_srv[0].fully_qualified_domain_name : ""
}

output "powerbi_sql_dw_server_database" {
  description = "Name of the Azure Synapse Analytics instance"
  value       = contains(azurerm_sql_database.synapse, 0) ? azurerm_sql_database.synapse[0].name : ""
}

output "powerbi_sql_dw_server_user" {
  description = "Username of the user dedicated to Power BI"
  value       = local.powerbi_viewer_user
}

output "powerbi_sql_dw_server_password" {
  description = "Password of the user dedicated to Power BI"
  value       = contains(random_password.sql_powerbi_viewer, 0) ? random_password.sql_powerbi_viewer[0].result : ""
}

output "service_principal_client_id" {
  description = "Client ID of the service principal that is used for service connections"
  value       = local.application_id
}

output "service_principal_client_secret" {
  sensitive   = true
  description = "Client secret of the service principal that is used for service connections"
  value       = local.service_principal_secret
}

output "service_principal_tenant_id" {
  description = "Tenant ID of the service principal that is used for service connections"
  value       = data.azurerm_client_config.current.tenant_id
}

output "data_factory_managed_identity" {
  description = "Principal Client ID of the created Azure Data Factory"
  value       = azurerm_data_factory.df.identity[0].principal_id
}
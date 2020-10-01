output "name" {
  description = "Name of the data lake"
  value       = var.data_lake_name
}

output "sql_dw_server_hostname" {
  description = "Name of the SQL server that hosts the Azure Synapse Analytics instance"
  value       = var.provision_synapse == 1 ? azurerm_sql_server.synapse_srv[0].fully_qualified_domain_name : ""
}

output "sql_dw_server_database" {
  description = "Name of the Azure Synapse Analytics instance"
  value       = var.provision_synapse == 1 ? azurerm_sql_database.synapse[0].name : ""
}

output "created_key_vault_secrets" {
  description = "Secrets that have been created inside the optional Key Vault with their versions"
  value       = local.created_secrets_all
}

output "storage_dfs_endpoint" {
  description = "Primary DFS endpoint of the created storage account"
  value       = azurerm_storage_account.adls.primary_dfs_endpoint
}

output "storage_account_name" {
  description = "Name of the created storage account for ADLS"
  value       = azurerm_storage_account.adls.name
}

output "data_factory_name" {
  description = "Name of the created Data Factory"
  value       = azurerm_data_factory.df.name
}

output "data_factory_identity" {
  description = "Object ID of the managed identity of the created Data Factory"
  value       = azurerm_data_factory.df.identity[0].principal_id
}

output "data_factory_id" {
  description = "Resource ID of the Data Factory"
  value       = azurerm_data_factory.df.id
}

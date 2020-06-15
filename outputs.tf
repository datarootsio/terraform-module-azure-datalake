output "name" {
  description = "Name of the data lake"
  value       = var.data_lake_name
}

output "powerbi_sql_dw_server_hostname" {
  description = "Name of the SQL server that hosts the Azure Synapse Analytics instance"
  value       = local.create_synapse == 1 ? azurerm_sql_server.synapse_srv[0].fully_qualified_domain_name : ""
}

output "powerbi_sql_dw_server_database" {
  description = "Name of the Azure Synapse Analytics instance"
  value       = local.create_synapse == 1 ? azurerm_sql_database.synapse[0].name : ""
}

output "powerbi_sql_dw_server_user" {
  description = "Username of the user dedicated to Power BI"
  value       = local.powerbi_viewer_user
}

output "powerbi_sql_dw_server_password" {
  description = "Password of the user dedicated to Power BI"
  value       = local.create_synapse == 1 ? random_password.sql_powerbi_viewer[0].result : ""
}

output "created_key_vault_secrets" {
  description = "Secrets that have been created inside the optional Key Vault with their versions"
  value = local.use_kv == 1 ? {
    "${azurerm_key_vault_secret.sp_id[0].name}"            = azurerm_key_vault_secret.sp_id[0].version,
    "${azurerm_key_vault_secret.sp_secret[0].name}"        = azurerm_key_vault_secret.sp_secret[0].version,
    "${azurerm_key_vault_secret.databricks_token[0].name}" = azurerm_key_vault_secret.databricks_token[0].version,
    "${azurerm_key_vault_secret.cosmosdb_connstr[0].name}" = azurerm_key_vault_secret.cosmosdb_connstr[0].version
  } : {}
}

output "storage_dfs_endpoint" {
  description = "Primary DFS endpoint of the created storage account"
  value       = azurerm_storage_account.adls.primary_dfs_endpoint
}

output "databricks_host" {
  description = "Databricks workspace hostname of the created workspace"
  value       = azurerm_databricks_workspace.dbks.workspace_url
}

output "databricks_cluster_id" {
  description = "ID of the cluster that is created inside the Databricks workspace"
  value       = databricks_cluster.cluster.id
}

output "service_principal_client_id" {
  description = "Client ID of the service principal that was used"
  value       = local.service_principal_id
}

output "data_factory_name" {
  description = "Name of the created Data Factory"
  value       = azurerm_data_factory.df.name
}

output "data_factory_identity" {
  description = "Object ID of the managed identity of the created Data Factory"
  value       = azurerm_data_factory.df.identity[0].principal_id
}

resource "azurerm_key_vault_access_policy" "df" {
  count              = local.use_kv
  key_vault_id       = var.key_vault_id
  tenant_id          = azurerm_data_factory.df.identity[0].tenant_id
  object_id          = azurerm_data_factory.df.identity[0].principal_id
  secret_permissions = ["list", "get"]
}

resource "azurerm_key_vault_secret" "sp_id" {
  count        = local.use_kv
  name         = "service-principal-client-id"
  value        = local.application_id
  key_vault_id = var.key_vault_id
  tags         = local.common_tags
}

resource "azurerm_key_vault_secret" "sp_secret" {
  count        = local.use_kv
  name         = "service-principal-client-secret"
  value        = local.service_principal_secret
  key_vault_id = var.key_vault_id
  tags         = local.common_tags
}

resource "azurerm_key_vault_secret" "databricks_token" {
  count        = var.use_key_vault && var.provision_databricks ? 1 : 0
  name         = "databricks-access-token"
  value        = databricks_token.token[count.index].token_value
  key_vault_id = var.key_vault_id
  tags         = local.common_tags
}

resource "azurerm_key_vault_secret" "cosmosdb_connstr" {
  count        = local.use_kv
  name         = "cosmosdb-connection-string"
  value        = "${azurerm_cosmosdb_account.cmdb.connection_strings[0]};Database=${azurerm_cosmosdb_sql_database.cmdb_db.name}"
  key_vault_id = var.key_vault_id
  tags         = local.common_tags
}
data "azurerm_key_vault" "kv" {
  depends_on          = [var.key_vault_depends_on]
  count               = local.use_kv
  resource_group_name = var.key_vault_resource_group
  name                = var.key_vault_name
}

resource "azurerm_key_vault_access_policy" "df" {
  depends_on              = [var.key_vault_depends_on]
  count                   = local.use_kv
  key_vault_id            = data.azurerm_key_vault.kv[count.index].id
  tenant_id               = azurerm_data_factory.df.identity[0].tenant_id
  object_id               = azurerm_data_factory.df.identity[0].principal_id
  secret_permissions      = ["list", "get"]
  key_permissions         = []
  storage_permissions     = []
  certificate_permissions = []
}

resource "azurerm_key_vault_secret" "sp_id" {
  depends_on   = [var.key_vault_depends_on]
  count        = local.use_kv
  name         = "service-principal-client-id"
  value        = local.application_id
  key_vault_id = data.azurerm_key_vault.kv[count.index].id
}

resource "azurerm_key_vault_secret" "sp_secret" {
  depends_on   = [var.key_vault_depends_on]
  count        = local.use_kv
  name         = "service-principal-client-secret"
  value        = local.service_principal_secret
  key_vault_id = data.azurerm_key_vault.kv[count.index].id
}

resource "azurerm_key_vault_secret" "databricks_token" {
  depends_on   = [var.key_vault_depends_on]
  count        = local.use_kv
  name         = "databricks-access-token"
  value        = databricks_token.token.token_value
  key_vault_id = data.azurerm_key_vault.kv[count.index].id
}

resource "azurerm_key_vault_secret" "cosmosdb_connstr" {
  depends_on   = [var.key_vault_depends_on]
  count        = local.use_kv
  name         = "cosmosdb-connection-string"
  value        = "${azurerm_cosmosdb_account.cmdb.connection_strings[0]};Database=${azurerm_cosmosdb_sql_database.cmdb_db.name}"
  key_vault_id = data.azurerm_key_vault.kv[count.index].id
}

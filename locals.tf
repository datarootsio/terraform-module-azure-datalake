locals {
  # Common tags to be assigned to all resources
  own_tags = {
    DataLake = var.data_lake_name
  }
  common_tags = merge(local.own_tags, var.extra_tags)

  data_lake_fs_merged = toset(concat([var.data_lake_fs_raw, var.data_lake_fs_cleansed, var.data_lake_fs_curated], var.data_lake_filesystems))

  create_sample                  = var.provision_sample_data && var.provision_databricks && var.provision_synapse && var.provision_data_factory_links ? 1 : 0
  create_synapse                 = var.provision_synapse ? 1 : 0
  create_data_factory_git_vsts   = var.data_factory_vsts_account_name == "" ? [] : ["_"]
  create_data_factory_git_github = var.data_factory_github_account_name == "" ? [] : ["_"]
  create_data_factory_ls         = var.provision_data_factory_links ? 1 : 0
  create_databricks              = var.provision_databricks ? 1 : 0
  use_kv                         = var.use_key_vault ? 1 : 0

  databricks_loader_user = "DatabricksLoader"
  powerbi_viewer_user    = "PowerBiViewer"

  service_principal_id     = var.use_existing_service_principal ? var.service_principal_id : join("", azuread_service_principal.sp.*.object_id)
  service_principal_secret = var.use_existing_service_principal ? var.service_principal_secret : join("", azuread_service_principal_password.sppw.*.value)
  application_id           = var.use_existing_service_principal ? var.application_id : join("", azuread_application.aadapp.*.application_id)

  created_secrets_1 = var.use_key_vault ? {
    (azurerm_key_vault_secret.sp_id[0].name)            = azurerm_key_vault_secret.sp_id[0].version,
    (azurerm_key_vault_secret.sp_secret[0].name)        = azurerm_key_vault_secret.sp_secret[0].version,
    (azurerm_key_vault_secret.cosmosdb_connstr[0].name) = azurerm_key_vault_secret.cosmosdb_connstr[0].version,
    (azurerm_key_vault_secret.storage_key[0].name)      = azurerm_key_vault_secret.storage_key[0].version
  } : {}
  created_secrets_2 = var.use_key_vault && var.provision_databricks ? {
    (azurerm_key_vault_secret.databricks_token[0].name) = azurerm_key_vault_secret.databricks_token[0].version
  } : {}
  created_secrets_all = merge(local.created_secrets_1, local.created_secrets_2)
}

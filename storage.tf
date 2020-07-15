resource "azurerm_storage_account" "adls" {
  name                     = "sa${var.data_lake_name}"
  location                 = var.region
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  access_tier              = "Cool"
  is_hns_enabled           = true
  account_replication_type = var.storage_replication
  tags                     = local.common_tags
}

resource "azurerm_role_assignment" "spsa_sa_adls" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = local.service_principal_id
}

resource "azurerm_role_assignment" "current_user_sa_adls" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "extra_contributor" {
  count                = length(var.extra_storage_contributor_ids)
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.extra_storage_contributor_ids[count.index]
}

resource "azurerm_role_assignment" "df_sa_adls" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_data_factory.df.identity[0].principal_id
}

resource "time_sleep" "adls_ra" {
  create_duration = "10s"

  triggers = {
    spsa_sa_adls         = azurerm_role_assignment.spsa_sa_adls.id
    current_user_sa_adls = azurerm_role_assignment.current_user_sa_adls.id
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "dlfs" {
  for_each           = local.data_lake_fs_merged
  name               = each.key
  storage_account_id = azurerm_storage_account.adls.id
  depends_on         = [azurerm_role_assignment.current_user_sa_adls, time_sleep.adls_ra]
}

resource "azurerm_storage_account" "dbkstemp" {
  count                    = var.provision_synapse && var.provision_databricks ? 1 : 0
  name                     = "sadbkstemp${var.data_lake_name}"
  location                 = var.region
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  access_tier              = "Hot"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

resource "azurerm_role_assignment" "current_user_sa_dbks" {
  count                = var.provision_synapse && var.provision_databricks ? 1 : 0
  scope                = azurerm_storage_account.dbkstemp[count.index].id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "spsa_sa_dbks" {
  count                = var.provision_synapse && var.provision_databricks ? 1 : 0
  scope                = azurerm_storage_account.dbkstemp[count.index].id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = local.service_principal_id
}

resource "time_sleep" "dbks_ra" {
  count           = var.provision_synapse && var.provision_databricks ? 1 : 0
  create_duration = "10s"

  triggers = {
    spsa_sa_adls         = azurerm_role_assignment.spsa_sa_dbks[count.index].id
    current_user_sa_adls = azurerm_role_assignment.current_user_sa_dbks[count.index].id
  }
}

resource "azurerm_storage_container" "databricks" {
  count                = var.provision_synapse && var.provision_databricks ? 1 : 0
  name                 = "databricks"
  storage_account_name = azurerm_storage_account.dbkstemp[count.index].name
  depends_on           = [time_sleep.dbks_ra, azurerm_role_assignment.current_user_sa_dbks]
}

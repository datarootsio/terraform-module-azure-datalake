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
  principal_id         = azuread_service_principal.sp.id
}

resource "azurerm_role_assignment" "current_user_sa_adls" {
  scope                = azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "time_sleep" "adls_ra" {
  create_duration = "10s"

  triggers = {
    spsa_sa_adls         = azurerm_role_assignment.spsa_sa_adls.id
    current_user_sa_adls = azurerm_role_assignment.current_user_sa_adls.id
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "dlfs" {
  count              = length(local.data_lake_fs_names)
  name               = local.data_lake_fs_names[count.index]
  storage_account_id = azurerm_storage_account.adls.id
  depends_on         = [azurerm_role_assignment.current_user_sa_adls, time_sleep.adls_ra]
}

resource "azurerm_storage_account" "dbkstemp" {
  name                     = "sadbkstemp${var.data_lake_name}"
  location                 = var.region
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  access_tier              = "Hot"
  account_replication_type = "LRS"
  tags                     = local.common_tags
}

resource "azurerm_role_assignment" "current_user_sa_dbks" {
  scope                = azurerm_storage_account.dbkstemp.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "spsa_sa_dbks" {
  scope                = azurerm_storage_account.dbkstemp.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.sp.id
}

resource "time_sleep" "dbks_ra" {
  create_duration = "10s"

  triggers = {
    spsa_sa_adls         = azurerm_role_assignment.spsa_sa_dbks.id
    current_user_sa_adls = azurerm_role_assignment.current_user_sa_dbks.id
  }
}

resource "azurerm_storage_container" "databricks" {
  name                 = "databricks"
  storage_account_name = azurerm_storage_account.dbkstemp.name
  depends_on           = [time_sleep.dbks_ra, azurerm_role_assignment.current_user_sa_dbks]
}

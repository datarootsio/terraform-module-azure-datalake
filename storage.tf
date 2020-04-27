resource "azurerm_storage_account" "dls" {
  name                     = "sa${var.data_lake_name}"
  location                 = var.region
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  access_tier              = "Cool"
  is_hns_enabled           = true
  account_replication_type = var.storage_replication
  tags                     = local.common_tags
}

resource "azurerm_role_assignment" "spsa" {
  scope                = azurerm_storage_account.dls.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.sp.id
}

resource "azurerm_role_assignment" "current_user" {
  scope                = azurerm_storage_account.dls.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "dlfs" {
  depends_on         = [azurerm_role_assignment.current_user]
  count              = length(local.data_lake_fs_names)
  name               = local.data_lake_fs_names[count.index]
  storage_account_id = azurerm_storage_account.dls.id
}
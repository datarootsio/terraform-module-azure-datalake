resource "azurerm_storage_account" "dls" {
  name                     = "sa${var.data_lake_name}"
  location                 = var.region
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  is_hns_enabled           = true
  account_replication_type = var.storage_replication
  tags                     = azurerm_resource_group.rg.tags
}

resource "azurerm_storage_data_lake_gen2_filesystem" "dlfs" {
  name               = "fs${var.data_lake_name}"
  storage_account_id = azurerm_storage_account.dls.id
}

resource "azurerm_role_assignment" "service_account_storage_account_owner" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Owner"
  principal_id         = azuread_service_principal.sp.object_id
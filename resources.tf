resource "azurerm_resource_group" "rg" {
  name     = "rg${var.data_lake_name}"
  location = var.region
  tags = {
    DataLake = var.data_lake_name
  }
}

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
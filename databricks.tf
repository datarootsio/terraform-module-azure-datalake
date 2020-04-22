resource "azurerm_databricks_workspace" "dbks" {
  name                        = "dbks${var.data_lake_name}"
  resource_group_name         = azurerm_resource_group.rg.name
  managed_resource_group_name = "rgdbks${var.data_lake_name}"
  location                    = var.region
  sku                         = var.databricks_sku
  tags                        = azurerm_resource_group.rg.tags
}
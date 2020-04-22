resource "azurerm_sql_server" "synapse_srv" {
  name                         = "dwsrv${var.data_lake_name}"
  location                     = var.region
  resource_group_name          = azurerm_resource_group.rg.name
  tags                         = azurerm_resource_group.rg.tags
  version                      = "12.0"
  administrator_login          = var.sql_server_admin_username
  administrator_login_password = var.sql_server_admin_password
}

resource "azurerm_sql_database" "synapse" {
  name                             = "dw${var.data_lake_name}"
  location                         = var.region
  resource_group_name              = azurerm_resource_group.rg.name
  server_name                      = azurerm_sql_server.synapse_srv.name
  tags                             = azurerm_resource_group.rg.tags
  edition                          = "DataWarehouse"
  requested_service_objective_name = var.data_warehouse_dtu
}
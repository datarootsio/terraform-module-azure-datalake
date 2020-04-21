resource "random_password" "synapse_srv_pw" {
  length = 32
}

resource "random_string" "synapse_srv_admin" {
  length  = 8
  special = false
}

resource "azurerm_sql_server" "synapse_srv" {
  name                         = "dwsrv${var.data_lake_name}"
  location                     = var.region
  resource_group_name          = azurerm_resource_group.rg.name
  tags                         = azurerm_resource_group.rg.tags
  version                      = "12.0"
  administrator_login          = random_string.synapse_srv_admin.result
  administrator_login_password = random_password.synapse_srv_pw.result
}

resource "azurerm_sql_database" "synapse" {
  name                = "dw${var.data_lake_name}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.synapse_srv.name
  tags                = azurerm_resource_group.rg.tags
}
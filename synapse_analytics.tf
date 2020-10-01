resource "azurerm_sql_server" "synapse_srv" {
  count                        = local.create_synapse_count
  name                         = "dwsrv${var.data_lake_name}"
  location                     = var.region
  resource_group_name          = var.resource_group_name
  tags                         = local.common_tags
  version                      = "12.0"
  administrator_login          = var.sql_server_admin_username
  administrator_login_password = var.sql_server_admin_password
}

resource "azurerm_sql_database" "synapse" {
  count                            = local.create_synapse_count
  name                             = "datawarehouse"
  location                         = var.region
  resource_group_name              = var.resource_group_name
  server_name                      = azurerm_sql_server.synapse_srv[count.index].name
  tags                             = local.common_tags
  edition                          = "DataWarehouse"
  requested_service_objective_name = var.data_warehouse_dtu
}

resource "azurerm_sql_firewall_rule" "allow_azure_services" {
  count               = local.create_synapse_count
  name                = "allow-azure-services"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_sql_server.synapse_srv[count.index].name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

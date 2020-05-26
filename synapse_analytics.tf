resource "azurerm_sql_server" "synapse_srv" {
  count                        = local.create_synapse
  name                         = "dwsrv${var.data_lake_name}"
  location                     = var.region
  resource_group_name          = azurerm_resource_group.rg.name
  tags                         = local.common_tags
  version                      = "12.0"
  administrator_login          = var.sql_server_admin_username
  administrator_login_password = var.sql_server_admin_password
}

resource "azurerm_sql_database" "synapse" {
  count                            = local.create_synapse
  name                             = "dw${var.data_lake_name}"
  location                         = var.region
  resource_group_name              = azurerm_resource_group.rg.name
  server_name                      = azurerm_sql_server.synapse_srv[count.index].name
  tags                             = local.common_tags
  edition                          = "DataWarehouse"
  requested_service_objective_name = var.data_warehouse_dtu
}

data "http" "current_ip" {
  count = local.create_synapse
  url   = "http://ipv4.icanhazip.com"
}

resource "azurerm_sql_firewall_rule" "allow_azure_services" {
  count               = local.create_synapse
  name                = "allow-azure-services"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.synapse_srv[count.index].name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_firewall_rule" "allow_current_ip" {
  count               = local.create_synapse
  name                = "terraform-deployment-rule"
  start_ip_address    = chomp(data.http.current_ip[count.index].body)
  end_ip_address      = chomp(data.http.current_ip[count.index].body)
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.synapse_srv[count.index].name
}

resource "random_password" "sql_databricks_loader" {
  count       = local.create_synapse
  length      = 100
  min_lower   = 10
  min_upper   = 10
  min_special = 10
  min_numeric = 10
}

resource "random_password" "sql_powerbi_viewer" {
  count       = local.create_synapse
  length      = 100
  min_lower   = 10
  min_upper   = 10
  min_special = 10
  min_numeric = 10
}

resource "null_resource" "sql_init" {
  count = local.create_synapse

  triggers = {
    every_time = timestamp()
  }

  depends_on = [
    azurerm_sql_firewall_rule.allow_current_ip
  ]

  provisioner "local-exec" {
    command = "pwsh -File ${path.module}/files/sql_init.ps1"
    environment = {
      SERVER                     = azurerm_sql_server.synapse_srv[count.index].fully_qualified_domain_name,
      DATABASE                   = azurerm_sql_database.synapse[count.index].name,
      USER                       = var.sql_server_admin_username,
      PASSWORD                   = var.sql_server_admin_password,
      DATABRICKS_LOADER_USER     = local.databricks_loader_user
      DATABRICKS_LOADER_PASSWORD = random_password.sql_databricks_loader[count.index].result
      POWERBI_VIEWER_USER        = local.powerbi_viewer_user
      POWERBI_VIEWER_PASSWORD    = random_password.sql_powerbi_viewer[count.index].result
    }
  }
}

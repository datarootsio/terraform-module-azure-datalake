resource "azurerm_sql_server" "synapse_srv" {
  name                         = "dwsrv${var.data_lake_name}"
  location                     = var.region
  resource_group_name          = azurerm_resource_group.rg.name
  tags                         = local.common_tags
  version                      = "12.0"
  administrator_login          = var.sql_server_admin_username
  administrator_login_password = var.sql_server_admin_password
}

resource "azurerm_sql_database" "synapse" {
  name                             = "dw${var.data_lake_name}"
  location                         = var.region
  resource_group_name              = azurerm_resource_group.rg.name
  server_name                      = azurerm_sql_server.synapse_srv.name
  tags                             = local.common_tags
  edition                          = "DataWarehouse"
  requested_service_objective_name = var.data_warehouse_dtu
}

data "http" "current_ip" {
  url = "http://ipv4.icanhazip.com"
}

resource "azurerm_sql_firewall_rule" "allow_azure_services" {
  name                = "allow-azure-services"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.synapse_srv.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_sql_firewall_rule" "allow_current_ip" {
  name                = "terraform-deployment-rule"
  start_ip_address    = chomp(data.http.current_ip.body)
  end_ip_address      = chomp(data.http.current_ip.body)
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.synapse_srv.name
}

resource "random_password" "sql_databricks_loader" {
  length = 16
}

resource "random_password" "sql_powerbi_viewer" {
  length = 16
}

resource "null_resource" "sql_init" {
  triggers = {
    every_time = timestamp()
  }

  depends_on = [
    azurerm_sql_firewall_rule.allow_current_ip
  ]

  provisioner "local-exec" {
    command = "pwsh -File ${path.module}/files/sql_init.ps1"
    environment = {
      SERVER                     = azurerm_sql_server.synapse_srv.fully_qualified_domain_name,
      DATABASE                   = azurerm_sql_database.synapse.name,
      USER                       = var.sql_server_admin_username,
      PASSWORD                   = var.sql_server_admin_password,
      DATABRICKS_LOADER_PASSWORD = random_password.sql_databricks_loader.result
      POWERBI_VIEWER_PASSWORD    = random_password.sql_powerbi_viewer.result
    }
  }
}

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

resource "local_file" "powershell_script" {
  sensitive_content = templatefile("${path.module}/files/db_init.ps1",
    {
      server   = azurerm_sql_server.synapse_srv.name,
      database = azurerm_sql_database.synapse.name,
      user     = var.sql_server_admin_username,
      password = var.sql_server_admin_password
  })

  filename = "/tmp/rendered_script.ps1"
}

resource "null_resource" "database_init" {

  triggers = {
    every_time = timestamp()
  }

  depends_on = [
    azurerm_sql_firewall_rule.allow_current_ip,
    azurerm_role_assignment.spsa_sa_adls
  ]

  provisioner "local-exec" {
    command = "pwsh -File ${local_file.powershell_script.filename} ${path.module}/files/script.sql"
  }
}

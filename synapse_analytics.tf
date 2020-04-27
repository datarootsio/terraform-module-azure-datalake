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

resource "azurerm_sql_firewall_rule" "allow_current_ip" {
  name                = "terraform-deployment-rule"
  start_ip_address    = chomp(data.http.current_ip.body)
  end_ip_address      = chomp(data.http.current_ip.body)
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.synapse_srv.name
}

resource "local_file" "sql_script" {
  sensitive_content = templatefile("${path.module}/files/script.sql",
    {
      user           = "${azuread_service_principal.sp.application_id}@https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/oauth2/token",
      secret         = random_password.aadapp_secret.result,
      account_name   = azurerm_storage_account.dls.name,
      data_lake_name = var.data_lake_name,
      containers     = local.data_lake_fs_names
  })

  filename = "/tmp/rendered_script.sql"
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
    build_number = timestamp()
  }

  depends_on = [
    azurerm_sql_firewall_rule.allow_current_ip
  ]

  provisioner "local-exec" {
    command     = local_file.powershell_script.filename
    interpreter = ["pwsh", "-File"]
  }
}

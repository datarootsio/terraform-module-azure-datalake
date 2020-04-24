resource "azurerm_databricks_workspace" "dbks" {
  name                        = "dbks${var.data_lake_name}"
  resource_group_name         = azurerm_resource_group.rg.name
  managed_resource_group_name = "rgdbks${var.data_lake_name}"
  location                    = var.region
  sku                         = var.databricks_sku
  tags                        = azurerm_resource_group.rg.tags
}

resource "null_resource" "databricks_token" {
  triggers = {
    build_number = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/files/generate_databricks_token.sh > /tmp/databricks_token.txt"
    environment = {
      DATABRICKS_WORKSPACE_RESOURCE_ID = azurerm_databricks_workspace.dbks.id
      DATABRICKS_ENDPOINT              = "https://${var.region}.azuredatabricks.net"
    }
  }
}

data "local_file" "databricks_token" {
  depends_on = [null_resource.databricks_token]
  filename   = "/tmp/databricks_token.txt"
}

module "databricks_sample_data" {
  source = "./databricks_sample_data"
  host   = "https://${lower(replace(var.region, " ", ""))}.azuredatabricks.net"
  token  = trimspace(data.local_file.databricks_token.content)
}
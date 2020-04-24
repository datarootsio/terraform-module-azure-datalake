resource "azurerm_databricks_workspace" "dbks" {
  name                        = "dbks${var.data_lake_name}"
  resource_group_name         = azurerm_resource_group.rg.name
  managed_resource_group_name = "rgdbks${var.data_lake_name}"
  location                    = var.region
  sku                         = var.databricks_sku
  tags                        = azurerm_resource_group.rg.tags
}

data "external" "databricks_token" {
  depends_on = [azurerm_databricks_workspace.dbks]
  program = ["bash", "${path.module}/files/generate_databricks_token.sh"]
  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    region               = lower(replace(var.region, " ", ""))
    databricks_workspace = azurerm_databricks_workspace.dbks.name
    resource_group       = azurerm_resource_group.rg.name
  }
}

module "databricks_sample_data" {
  source = "./databricks_sample_data"
  host   = "https://${lower(replace(var.region, " ", ""))}.azuredatabricks.net"
  token  = data.external.databricks_token.result["token"]
}
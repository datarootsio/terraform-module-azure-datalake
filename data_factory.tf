resource "azurerm_data_factory" "df" {
  name                = "df${var.data_lake_name}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "lsadls" {
  name                  = "lsadls${var.data_lake_name}"
  resource_group_name   = azurerm_resource_group.rg.name
  data_factory_name     = azurerm_data_factory.df.name
  tenant                = data.azurerm_client_config.current.tenant_id
  url                   = "https://${azurerm_storage_account.adls.name}.dfs.core.windows.net/"
  service_principal_id  = azuread_application.aadapp.application_id
  service_principal_key = azuread_service_principal_password.sppw.value
}

resource "azurerm_template_deployment" "lsdbks" {
  name                = "lsdbks${var.data_lake_name}"
  resource_group_name = azurerm_resource_group.rg.name

  template_body = <<DEPLOY
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "factoryName": {
            "type": "string"
        },
        "accessToken": {
            "type": "secureString"
        },
        "domain": {
            "type": "string"
        },
        "databricksName": {
            "type": "string"
        }
    },
    "resources": [
        {
            "name": "[concat(parameters('factoryName'), '/', parameters('databricksName'))]",
            "type": "Microsoft.DataFactory/factories/linkedServices",
            "apiVersion": "2018-06-01",
            "properties": {
                "annotations": [],
                "type": "AzureDatabricks",
                "typeProperties": {
                    "domain": "[parameters('domain')]",
                    "accessToken": {
                        "type": "SecureString",
                        "value": "[parameters('accessToken')]"
                    },
                    "existingClusterId": "0506-134952-froze143"
                }
            }
        }
    ]
}
DEPLOY


  # these key-value pairs are passed into the ARM Template's `parameters` block
  parameters = {
    "factoryName"    = azurerm_data_factory.df.name
    "accessToken"    = databricks_token.token.token_value
    "domain"         = format("https://%s.azuredatabricks.net", azurerm_databricks_workspace.dbks.location)
    "databricksName" = azurerm_databricks_workspace.dbks.name
  }

  deployment_mode = "Incremental"
}

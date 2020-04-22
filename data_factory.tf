resource "azurerm_data_factory" "df" {
  name                = "df${var.data_lake_name}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  tags                = azurerm_resource_group.rg.tags
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "dfdsl" {
  name                  = "dfls${var.data_lake_name}"
  resource_group_name   = azurerm_resource_group.rg.name
  data_factory_name     = azurerm_data_factory.df.name
  tenant                = data.azurerm_client_config.current.tenant_id
  url                   = "https://${azurerm_storage_account.dls.name}.dfs.core.windows.net/"
  service_principal_id  = azuread_application.aadapp.application_id
  service_principal_key = random_password.aadapp_secret.result
}
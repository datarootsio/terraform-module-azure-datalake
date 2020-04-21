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
  url                   = "https://${azurerm_storage_account.dls.name}.blob.core.windows.net/${azurerm_storage_data_lake_gen2_filesystem.dlfs.name}"
  service_principal_id  = azuread_service_principal.oidc_principal.object_id
  service_principal_key = azuread_application_password.aadapp-srv.id // TODO: verify if we need ID or key itself
}
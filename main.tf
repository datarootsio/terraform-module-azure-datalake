data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_role_assignment" "sprg" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Owner"
  principal_id         = var.service_principal_object_id
}

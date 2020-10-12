provider "azurerm" {
  features {}
}

resource "random_string" "test_id" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  location = var.region
  name     = "rg${local.data_lake_name}"
  tags     = local.tags
}

resource "azurerm_databricks_workspace" "dbks" {
  name                        = "dbks${local.data_lake_name}"
  resource_group_name         = azurerm_resource_group.rg.name
  managed_resource_group_name = "rgdbks${local.data_lake_name}"
  location                    = var.region
  sku                         = "standard"
  tags                        = local.tags
}

provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.dbks.id
}

resource "azuread_application" "sp" {
  name = "app-${local.data_lake_name}"
  required_resource_access {
    resource_app_id = "e406a681-f3d4-42a8-90b6-c2b029497af1"
    resource_access {
      id   = "03e0da56-190b-40ad-a80c-ea378c433f7f"
      type = "Scope"
    }
  }
  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }
}

resource "random_password" "sp" {
  length = 64
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.sp.application_id
  tags           = [local.data_lake_name]
}

resource "azuread_service_principal_password" "sp" {
  service_principal_id = azuread_service_principal.sp.id
  value                = random_password.sp.result
  end_date_relative    = "24h"
}

resource "random_pet" "sql" {}
resource "random_password" "sql" {
  length = 64
}

module "azure-datalake" {
  depends_on                      = [azurerm_databricks_workspace.dbks]
  source                          = "../../"
  data_lake_name                  = local.data_lake_name
  region                          = var.region
  storage_replication             = "LRS"
  resource_group_name             = azurerm_resource_group.rg.name
  service_principal_client_id     = azuread_application.sp.application_id
  service_principal_client_secret = azuread_service_principal_password.sp.value
  service_principal_object_id     = azuread_service_principal.sp.object_id
  databricks_workspace_name       = azurerm_databricks_workspace.dbks.name
  sql_server_admin_username       = random_pet.sql.id
  sql_server_admin_password       = random_password.sql.result
  provision_databricks_resources  = true
  extra_tags                      = local.tags
}

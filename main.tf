terraform {
  required_version = "~> 0.12"
  required_providers {
    azurerm = ">= 2.11.0"
    azuread = ">= 0.8.0"
    databricks = {
      source  = "databrickslabs/databricks"
      version = ">= 0.2.3"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {
}

resource "azuread_application" "aadapp" {
  count = var.use_existing_service_principal ? 0 : 1
  name  = "app-${var.data_lake_name}"
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

resource "random_password" "aadapp_secret" {
  count  = var.use_existing_service_principal ? 0 : 1
  length = 32
}

resource "azuread_service_principal" "sp" {
  count          = var.use_existing_service_principal ? 0 : 1
  application_id = azuread_application.aadapp[0].application_id
  tags           = [var.data_lake_name]
}

resource "azuread_service_principal_password" "sppw" {
  count                = var.use_existing_service_principal ? 0 : 1
  service_principal_id = azuread_service_principal.sp[0].id
  value                = random_password.aadapp_secret[0].result
  end_date             = var.service_principal_end_date
}

resource "azurerm_resource_group" "rg" {
  name     = "rg${var.data_lake_name}"
  location = var.region
  tags     = local.common_tags
}

resource "azurerm_role_assignment" "sprg" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Owner"
  principal_id         = local.service_principal_id
}

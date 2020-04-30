terraform {
  required_version = "~> 0.12"
  required_providers {
    azurerm = "~> 2.6.0"
    azuread = "~> 0.8.0"
  }
}

provider "azurerm" {
  version = "~> 2.6.0"
  features {}
}

provider "azuread" {
  version = "~> 0.8.0"
}

data "azurerm_client_config" "current" {
}

resource "azuread_application" "aadapp" {
  name = "app-${var.data_lake_name}"
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
  length  = 32
  special = false # temp workaround for https://github.com/databrickslabs/databricks-terraform/issues/21
}

resource "azuread_service_principal" "sp" {
  application_id = azuread_application.aadapp.application_id
  tags           = [var.data_lake_name]
}

resource "azuread_service_principal_password" "sppw" {
  service_principal_id = azuread_service_principal.sp.id
  value                = random_password.aadapp_secret.result
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
  principal_id         = azuread_service_principal.sp.object_id
}

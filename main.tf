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
}

resource "random_password" "oidc_client_secret" {
  length = 32
}

resource "azuread_service_principal" "oidc_principal" {
  application_id = azuread_application.aadapp.application_id
  tags           = [var.data_lake_name]
}

resource "azuread_application_password" "aadapp-srv" {
  application_object_id = azuread_application.aadapp.object_id
  value                 = random_password.oidc_client_secret.result
  end_date              = var.service_principal_end_date
}

resource "azurerm_resource_group" "rg" {
  name     = "rg${var.data_lake_name}"
  location = var.region
  tags = {
    DataLake = var.data_lake_name
  }
}
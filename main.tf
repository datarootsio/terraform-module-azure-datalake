terraform {
  required_version = "~> 0.12"
  required_providers {
    azurerm = ">= 2.6.0"
  }
}

provider "azurerm" {
  version = ">= 2.6.0"
  features {}
}

provider "azuread" {
}
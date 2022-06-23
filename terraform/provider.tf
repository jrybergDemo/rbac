terraform {
  required_providers {
    azuread = "~> 2.8.0"
    azurerm = "~> 2.83.0"
    random  = "~> 3.1.0"
  }
  backend "azurerm" {}
}

provider "azuread" {}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

provider "random" {}

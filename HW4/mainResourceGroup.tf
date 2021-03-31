terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      	version = "2.53.0"
    }
  }
}

provider "azurerm" {
	subscription_id = var.subscriptionID
	features {}
}

resource "azurerm_resource_group" "NoteezyRG" {
  name     = var.resourceGroupName
  location = var.location
}
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

resource "azurerm_network_security_group" "NoteezySecurityGroup" {
  name                = "NoteezySecurityGroup"
  location            = var.location
  resource_group_name = var.resourceGroupName
}

resource "azurerm_network_security_rule" "Port80" {
  name                        = "Allow80"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.NoteezySecurityGroup.resource_group_name
  network_security_group_name = azurerm_network_security_group.NoteezySecurityGroup.name
}

resource "azurerm_network_security_rule" "Port443" {
  name                        = "Allow443"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.NoteezySecurityGroup.resource_group_name
  network_security_group_name = azurerm_network_security_group.NoteezySecurityGroup.name
}

resource "azurerm_network_security_rule" "Port22" {
  name                        = "Allow22"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.NoteezySecurityGroup.resource_group_name
  network_security_group_name = azurerm_network_security_group.NoteezySecurityGroup.name
}

resource "azurerm_network_security_rule" "Port80_Out" {
  name                        = "Allow80_Out"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.NoteezySecurityGroup.resource_group_name
  network_security_group_name = azurerm_network_security_group.NoteezySecurityGroup.name
}

resource "azurerm_network_security_rule" "Port443_Out" {
  name                        = "Allow443_Out"
  priority                    = 101
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.NoteezySecurityGroup.resource_group_name
  network_security_group_name = azurerm_network_security_group.NoteezySecurityGroup.name
}

resource "azurerm_network_security_rule" "Port22_Out" {
  name                        = "Allow22_Out"
  priority                    = 102
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.NoteezySecurityGroup.resource_group_name
  network_security_group_name = azurerm_network_security_group.NoteezySecurityGroup.name
}

resource "azurerm_virtual_network" "NoteezyVNET" {
  name                = "NoteezyVNET"
  location            = var.location
  resource_group_name = var.resourceGroupName
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["8.8.8.8", "8.8.4.4"]
}

resource "azurerm_subnet" "NoteezySubNet" {
  name                 = "NoteezySubNet"
  resource_group_name  = azurerm_network_security_group.NoteezySecurityGroup.resource_group_name
  virtual_network_name = azurerm_virtual_network.NoteezyVNET.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "NoteezyPublicIP" {
	count = var.vmCount
	name = "Noteezy-${count.index}-PublicIP"
	location            = var.location
	resource_group_name = azurerm_network_security_group.NoteezySecurityGroup.resource_group_name
	allocation_method = "Static"
}

resource "azurerm_network_interface" "VMInterface" {
	count = var.vmCount
	name                = "VMInterface-${count.index}"
	location            = azurerm_network_security_group.NoteezySecurityGroup.location
	resource_group_name = azurerm_network_security_group.NoteezySecurityGroup.resource_group_name
  
	ip_configuration {
		name = "internal"
		subnet_id = azurerm_subnet.NoteezySubNet.id
		private_ip_address_allocation = "Dynamic"
		public_ip_address_id = element(azurerm_public_ip.NoteezyPublicIP.*.id, count.index)
	}
	
	provisioner "local-exec" {
		command = "echo ${azurerm_public_ip.NoteezyPublicIP[count.index].ip_address} >> ../ipAddress.txt"
  }
}

resource "azurerm_network_interface_security_group_association" "NetworkInterfaceSecurityGroup" {
  count = var.vmCount
  network_interface_id      = element(azurerm_network_interface.VMInterface.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.NoteezySecurityGroup.id
}

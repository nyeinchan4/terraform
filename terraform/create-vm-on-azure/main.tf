#create vm on azure

# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

#create resource group
resource "azurerm_resource_group" "myapp-resource" {
  name     = "myapp-resource"
  location = "Japan East"
}

#create virtual network
resource "azurerm_virtual_network" "myapp-vnet" {
  name                = "myapp-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myapp-resource.location
  resource_group_name = azurerm_resource_group.myapp-resource.name
}

#create subnet
resource "azurerm_subnet" "myapp-subnet-1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.myapp-resource.name
  virtual_network_name = azurerm_virtual_network.myapp-vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

#create public ip
resource "azurerm_public_ip" "myapp-public-ip" {
  name                = "myap-public-ip"
  resource_group_name = azurerm_resource_group.myapp-resource.name
  location            = azurerm_resource_group.myapp-resource.location
  allocation_method   = "Static"

  tags = {
    environment = "Dev"
  }
}

#create network card
resource "azurerm_network_interface" "myapp-nic" {
  name                = "myapp-nic"
  location            = azurerm_resource_group.myapp-resource.location
  resource_group_name = azurerm_resource_group.myapp-resource.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.myapp-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.myapp-public-ip.id
  }
}

#create security group
resource "azurerm_network_security_group" "myapp-sg" {
  name                = "myapp-sg"
  location            = azurerm_resource_group.myapp-resource.location
  resource_group_name = azurerm_resource_group.myapp-resource.name

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Dev"
  }
}

#create linux virtual machine
resource "azurerm_linux_virtual_machine" "myapp-server" {
  name                = "myapp-server"
  resource_group_name = azurerm_resource_group.myapp-resource.name
  location            = azurerm_resource_group.myapp-resource.location
  size                = "Standard_B1s"
  admin_username      = "rastarure"
  admin_password      = "Azayaore08376"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.myapp-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}


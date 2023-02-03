#create two vm with different network range and make azure vnet perring

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

#create resource gp
resource "azurerm_resource_group" "myapp" {
  name     = "myapp"
  location = "Japan East"
}

#create myapp-1-Vnet
resource "azurerm_virtual_network" "myapp-1-Vnet" {
  name                = "myapp-1-Vnet"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.myapp.location
  resource_group_name = azurerm_resource_group.myapp.name
}

#creating subnet on myapp-1-Vnet
resource "azurerm_subnet" "myapp-subnet-1" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.myapp.name
  virtual_network_name = azurerm_virtual_network.myapp-1-Vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

#create public ip on myapp-1-Vnet
resource "azurerm_public_ip" "myapp-public-ip-1-Vnet" {
  name                = "myap-public-ip-1-Vnet"
  resource_group_name = azurerm_resource_group.myapp.name
  location            = azurerm_resource_group.myapp.location
  allocation_method   = "Static"

  tags = {
    environment = "Dev"
  }
}

#create network card on myapp-1-Vnet
resource "azurerm_network_interface" "myapp-nic-1-Vnet" {
  name                = "myapp-nic-1-Vnet"
  location            = azurerm_resource_group.myapp.location
  resource_group_name = azurerm_resource_group.myapp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.myapp-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.myapp-public-ip-1-Vnet.id
  }
}

#create security group on myapp-1-Vnet
resource "azurerm_network_security_group" "myapp-sg" {
  name                = "myapp-sg-1-Vnet"
  location            = azurerm_resource_group.myapp.location
  resource_group_name = azurerm_resource_group.myapp.name

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

#associate NSG and subnet on Vnet-1
resource "azurerm_subnet_network_security_group_association" "associate-nsg-subnet-1" {
  subnet_id                 = azurerm_subnet.myapp-subnet-1.id
  network_security_group_id = azurerm_network_security_group.myapp-sg.id
}

#create linux virtual machine for myapp-1-Vnet
resource "azurerm_linux_virtual_machine" "myapp-server-Vnet1" {
  name                = "myapp-server-Vnet1"
  resource_group_name = azurerm_resource_group.myapp.name
  location            = azurerm_resource_group.myapp.location
  size                = "Standard_B1s"
  admin_username      = "rastarure"
  admin_password      = "Azayaore08376"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.myapp-nic-1-Vnet.id,
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

#create myapp-2-Vnet
resource "azurerm_virtual_network" "myapp-2-Vnet" {
  name                = "myapp-2-Vnet"
  address_space       = ["10.0.1.0/24"]
  location            = azurerm_resource_group.myapp.location
  resource_group_name = azurerm_resource_group.myapp.name
}

#creating subnet on myapp-2-Vnet
resource "azurerm_subnet" "myapp-subnet-2" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.myapp.name
  virtual_network_name = azurerm_virtual_network.myapp-2-Vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#create public ip on myapp-2-Vnet
resource "azurerm_public_ip" "myapp-public-ip-2-Vnet" {
  name                = "myap-public-ip-2-Vnet"
  resource_group_name = azurerm_resource_group.myapp.name
  location            = azurerm_resource_group.myapp.location
  allocation_method   = "Static"

  tags = {
    environment = "Dev"
  }
}

#create network card on myapp-2-Vnet
resource "azurerm_network_interface" "myapp-nic-2-Vnet" {
  name                = "myapp-nic-2-Vnet"
  location            = azurerm_resource_group.myapp.location
  resource_group_name = azurerm_resource_group.myapp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.myapp-subnet-2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.myapp-public-ip-2-Vnet.id
  }
}

#create security group on myapp-2-Vnet
resource "azurerm_network_security_group" "myapp-sg-2-Vnet" {
  name                = "myapp-sg-2-Vnet"
  location            = azurerm_resource_group.myapp.location
  resource_group_name = azurerm_resource_group.myapp.name

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

resource "azurerm_subnet_network_security_group_association" "associate-nsg-subnet2" {
  subnet_id                 = azurerm_subnet.myapp-subnet-2.id
  network_security_group_id = azurerm_network_security_group.myapp-sg-2-Vnet.id
}

#create linux virtual machine for myapp-2-Vnet
resource "azurerm_linux_virtual_machine" "myapp-server-Vnet2" {
  name                = "myapp-server-Vnet2"
  resource_group_name = azurerm_resource_group.myapp.name
  location            = azurerm_resource_group.myapp.location
  size                = "Standard_B1s"
  admin_username      = "rastarure"
  admin_password      = "Azayaore08376"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.myapp-nic-2-Vnet.id,
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

#create peering myapp-2to1
resource "azurerm_virtual_network_peering" "peer-myapp-2to1" {
  name                      = "peer-myapp-2to1"
  resource_group_name       = azurerm_resource_group.myapp.name
  virtual_network_name      = azurerm_virtual_network.myapp-2-Vnet.name
  remote_virtual_network_id = azurerm_virtual_network.myapp-1-Vnet.id
}

#create peering myapp-1to2
resource "azurerm_virtual_network_peering" "peer-myapp-1to2" {
  name                      = "peer-myapp-1to2"
  resource_group_name       = azurerm_resource_group.myapp.name
  virtual_network_name      = azurerm_virtual_network.myapp-1-Vnet.name
  remote_virtual_network_id = azurerm_virtual_network.myapp-2-Vnet.id
}

#to see myapp-server-Vnet1 ip
output "myapp-server-Vnet1" {
    value = azurerm_linux_virtual_machine.myapp-server-Vnet1.id
}

#to see myapp-server-Vnet2 ip
output "myapp-server-Vnet2" {
    value = azurerm_linux_virtual_machine.myapp-server-Vnet2.id
}

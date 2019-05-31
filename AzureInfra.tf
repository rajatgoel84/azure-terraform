
###CREATE PRINCIPLE
# az login
# az account set --subscription="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
# az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
# principle
# {
#   "appId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",#CLIENT_ID
#   "displayName": "azure-cli-2019-05-29-03-23-07",
#   "name": "http://azure-cli-2019-05-29-03-23-07",
#   "password": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",#CLIENT_SECRET
#   "tenant": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"#TENANT_ID
# }
# az login --service-principal -u CLIENT_ID -p CLIENT_SECRET --tenant TENANT_ID
# example : az login --service-principal -u XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -p XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX --tenant XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.28.0"
  # subscription_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  # client_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  # client_secret = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  # tenant_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
 }

resource "azurerm_resource_group" "cbrecloud_prod_resourcegrp" {  
  name     = "cbre_gtaw_prod_resourcegrp"  
  location = "${var.location}"  
}  
         
resource "azurerm_public_ip" "cbrecloud_publicip" {  //Here defined the public IP
  name                         = "cbrecloudpublicip"  
  location                     = "${var.location}"  
  resource_group_name          = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
  allocation_method            = "Dynamic"  
  idle_timeout_in_minutes      = 30  
  domain_name_label            = "cbrecloudvm"  //Here defined the dns name
  
  # tags {  
  #   environment = "production"  
  # }  
}  
  
resource "azurerm_virtual_network" "cbrecloud_vnet" {   //Here defined the virtual network
  name                = "cbrecloudvnet"  
  address_space       = ["10.0.0.0/16"]  
  location            = "${var.location}"  
  resource_group_name = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
}  
  
resource "azurerm_network_security_group" "cbrecloud_nsg" {  //Here defined the network secrity group
  name                = "cbrecloudnsg"  
  location            = "${var.location}"  
  resource_group_name = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
  
  security_rule {  //Here opened https port
    name                       = "HTTPS"  
    priority                   = 1000  
    direction                  = "Inbound"  
    access                     = "Allow"  
    protocol                   = "Tcp"  
    source_port_range          = "*"  
    destination_port_range     = "443"  
    source_address_prefix      = "*"  
    destination_address_prefix = "*"  
  }  
  security_rule {   //Here opened WinRMport
    name                       = "winrm"  
    priority                   = 1010  
    direction                  = "Inbound"  
    access                     = "Allow"  
    protocol                   = "Tcp"  
    source_port_range          = "*"  
    destination_port_range     = "5985"  
    source_address_prefix      = "*"  
    destination_address_prefix = "*"  
  }  
  security_rule {   //Here opened https port for outbound
    name                       = "winrm-out"  
    priority                   = 100  
    direction                  = "Outbound"  
    access                     = "Allow"  
    protocol                   = "*"  
    source_port_range          = "*"  
    destination_port_range     = "5985"  
    source_address_prefix      = "*"  
    destination_address_prefix = "*"  
  }  
  security_rule {   //Here opened remote desktop port
    name                       = "RDP"  
    priority                   = 110  
    direction                  = "Inbound"  
    access                     = "Allow"  
    protocol                   = "Tcp"  
    source_port_range          = "*"  
    destination_port_range     = "3389"  
    source_address_prefix      = "*"  
    destination_address_prefix = "*"  
  }  
  # tags {  
  #   environment = "production"  
  # }  
}  
  
resource "azurerm_subnet" "cbrecloud_subnet" {   //Here defined subnet
  name                 = "cbrecloudsubnet"  
  resource_group_name  = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
  virtual_network_name = "${azurerm_virtual_network.cbrecloud_vnet.name}"  
  address_prefix       = "10.0.2.0/24"  
}  
  
resource "azurerm_network_interface" "cbrecloud_nic" {  //Here defined network interface
  name                      = "cbrecloudnic"  
  location                  = "${var.location}"  
  resource_group_name       = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
  network_security_group_id = "${azurerm_network_security_group.cbrecloud_nsg.id}"  
  
  ip_configuration {  
    name                          = "cbrecloudconfiguration"  
    subnet_id                     = "${azurerm_subnet.cbrecloud_subnet.id}"  
    private_ip_address_allocation = "dynamic"  
    public_ip_address_id          = "${azurerm_public_ip.cbrecloud_publicip.id}"  
  }  
}  
  
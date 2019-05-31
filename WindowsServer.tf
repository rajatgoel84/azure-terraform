
resource "azurerm_storage_account" "cbrecloud_storageacc" {  //Here defined a storage account for disk
  name                     = "cbrecloudstgacc"  
  resource_group_name      = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
  location                 = "${var.location}"  
  account_tier             = "Standard"  
  account_replication_type = "GRS"  
}  
  
resource "azurerm_storage_container" "cbrecloud_storagecont" {  //Here defined a storage account container for disk
  name                  = "cbrecloudstoragecont"  
  resource_group_name   = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
  storage_account_name  = "${azurerm_storage_account.cbrecloud_storageacc.name}"  
  container_access_type = "private"  
}  
  
resource "azurerm_managed_disk" "cbrecloud_datadisk" {  //Here defined data disk structure
  name                 = "cbreclouddatadisk"  
  location             = "${var.location}"  
  resource_group_name  = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
  storage_account_type = "Standard_LRS"  
  create_option        = "Empty"  
  disk_size_gb         = "1023"  
}  
  
resource "azurerm_virtual_machine" "cbrecloud_vm" {  //Here defined virtual machine
  name                  = "cbrecloudvm"  
  location              = "${var.location}"  
  resource_group_name   = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
  network_interface_ids = ["${azurerm_network_interface.cbrecloud_nic.id}"]  
  vm_size               = "Standard_B1ls"  //Here defined virtual machine size
  
  storage_image_reference {  //Here defined virtual machine OS
    publisher = "MicrosoftWindowsServer"  
    offer     = "WindowsServer"  
    sku       = "2019-Datacenter"  
    version   = "latest"  
  }  
 
  storage_os_disk {  //Here defined OS disk
    name              = "cbrecloudosdisk"  
    caching           = "ReadWrite"  
    create_option     = "FromImage"  
    managed_disk_type = "Standard_LRS"  
    #  vhd_uri             = "${var.mycustimg}"
  }  
  
  storage_data_disk {  //Here defined actual data disk by referring to above structure
    name            = "${azurerm_managed_disk.cbrecloud_datadisk.name}"  
    managed_disk_id = "${azurerm_managed_disk.cbrecloud_datadisk.id}"  
    create_option   = "Attach"  
    lun             = 1  
    disk_size_gb    = "${azurerm_managed_disk.cbrecloud_datadisk.disk_size_gb}"  
  }  
  
  os_profile {  //Here defined admin uid/pwd and also comupter name
    computer_name  = "cbrecloudhost"  
    admin_username = "${var.username}"  
    admin_password = "${var.password}"  
  }  
  
  os_profile_windows_config {  //Here defined autoupdate config and also vm agent config
    enable_automatic_upgrades = true  
    provision_vm_agent        = true  
  
    # //Here defined WinRM connectivity config
    # winrm ={
    #   protocol="http"
    # }
    # # Auto-Login's required to configure WinRM
    # additional_unattend_config {
    #   pass         = "oobeSystem"
    #   component    = "Microsoft-Windows-Shell-Setup"
    #   setting_name = "AutoLogon"
    #   content      = "<AutoLogon><Password><Value>${var.password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.username}</Username></AutoLogon>"
    # }

    # # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    # additional_unattend_config {
    #   pass         = "oobeSystem"
    #   component    = "Microsoft-Windows-Shell-Setup"
    #   setting_name = "FirstLogonCommands"
    #   content      = "${file("./files/FirstLogonCommands.xml")}"
    # }
  }
  tags = {
    environment = "production"
  }  
}  


##########################################################
## Install IIS & .NET4.5 on VM
##########################################################

resource "azurerm_virtual_machine_extension" "cbrecloud_vmiis" {
  name                 = "cbrecloudvmiis"
  resource_group_name  = "${azurerm_resource_group.cbrecloud_prod_resourcegrp.name}"  
  location             = "${var.location}"  
  virtual_machine_name =  "${azurerm_virtual_machine.cbrecloud_vm.name}"  
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings = <<SETTINGS
    { 
      "commandToExecute": "powershell Add-WindowsFeature Web-Asp-Net45;Add-WindowsFeature NET-Framework-45-Core;Add-WindowsFeature Web-Net-Ext45;Add-WindowsFeature Web-ISAPI-Ext;Add-WindowsFeature Web-ISAPI-Filter;Add-WindowsFeature Web-Mgmt-Console;Add-WindowsFeature Web-Scripting-Tools;Add-WindowsFeature Search-Service;Add-WindowsFeature Web-Filtering;Add-WindowsFeature Web-Basic-Auth;Add-WindowsFeature Web-Windows-Auth;Add-WindowsFeature Web-Default-Doc;Add-WindowsFeature Web-Http-Errors;Add-WindowsFeature Web-Static-Content;Add-WindowsFeature Web-Server;"
    } 
SETTINGS
}
resource "azurerm_resource_group" "devops_bootcamp_rg"{
    name = "DevopsBootcamp_RG"
    location = var.location
}

resource "azurerm_virtual_network" "devops_bootcamp_vnet"{
    name = "DevopsVNet"
    address_space = ["10.0.0.0/16"]
    location = var.location
    resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
}

resource "azurerm_subnet" "devops_bootcamp_subnet"{
    name = "DevopsSb"
    resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
    virtual_network_name = azurerm_virtual_network.devops_bootcamp_vnet.name
    address_prefixes = ["10.0.0.0/17"]
}

resource "azurerm_subnet" "devops_bootcamp_subnet2"{
    name = "DevopsSb2"
    resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
    virtual_network_name = azurerm_virtual_network.devops_bootcamp_vnet.name
    address_prefixes = ["10.0.128.0/17"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "PublicIP"
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
  location            = azurerm_resource_group.devops_bootcamp_rg.location
  allocation_method   = "Static"
  sku = "Basic"

  tags = {
    environment = var.env
  }
}

# resource "azurerm_network_security_group" "general_security" {
#   name = "${var.env}-${var.product}-windows-vm-nsg"
#   location            = azurerm_resource_group.devops_bootcamp_rg.location
#   resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
#   security_rule {
#     name                       = "allow-rdp"
#     description                = "allow-rdp"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "3389"
#     source_address_prefix      = var.sourceip
#     destination_address_prefix = "*" 
#   }
# }
resource "azurerm_network_security_group" "general_security" {
  name                = "${var.env}-${var.product}-windows-vm-nsg"
  location            = azurerm_resource_group.devops_bootcamp_rg.location
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name

  security_rule {
    name                       = "allow-rdp"
    description                = "allow-rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.sourceip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    description                = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.sourceip
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface" "windows_nic" {
  name                = "WindowsNIC-01"
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name

  ip_configuration {
    name                          = "general"
    subnet_id                     = azurerm_subnet.devops_bootcamp_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_network_interface" "windows_nic2" {
  name                = "WindowsNIC-02"
  location            = var.location
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name

  ip_configuration {
    name                          = "general"
    subnet_id                     = azurerm_subnet.devops_bootcamp_subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "vm_rdp_group" {
  network_interface_id      = azurerm_network_interface.windows_nic.id
  network_security_group_id = azurerm_network_security_group.general_security.id
}

resource "azurerm_subnet_network_security_group_association" "vm_sns_group" {
  subnet_id                 = azurerm_subnet.devops_bootcamp_subnet.id
  network_security_group_id = azurerm_network_security_group.general_security.id
}

data "template_file" "powershell_init"{
  template = file("user_data.ps1")
}

resource "azurerm_windows_virtual_machine" "windows_server" {
  name                = "WindowsServer"
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = var.password # move to vault or to get it from variables
  network_interface_ids = [
    azurerm_network_interface.windows_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  #C:\AzureData
  custom_data = base64encode(data.template_file.powershell_init.rendered)

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "windows_server2" {
  name                = "WindowsServer2"
  resource_group_name = azurerm_resource_group.devops_bootcamp_rg.name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = var.password
  network_interface_ids = [
    azurerm_network_interface.windows_nic2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(data.template_file.powershell_init.rendered)

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "execute-userdata" {
  #depends_on=[azurerm_windows_virtual_machine.web-windows-vm]
  name = "SetupGitlabRunner"
  virtual_machine_id = azurerm_windows_virtual_machine.windows_server.id
  publisher = "Microsoft.Compute"
  type = "CustomScriptExtension"
  type_handler_version = "1.9"
  settings = <<SETTINGS
    { 
      "commandToExecute": "powershell rename-item  C:\\AzureData\\CustomData.bin -newname CustomData.ps1 ;powershell C:\\AzureData\\CustomData.ps1;"
    } 
  SETTINGS
}

resource "azurerm_virtual_machine_extension" "execute-userdata2" {
  name                 = "SetupGitlabRunner2"
  virtual_machine_id   = azurerm_windows_virtual_machine.windows_server2.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  settings = <<SETTINGS
    { 
      "commandToExecute": "powershell rename-item  C:\\AzureData\\CustomData.bin -newname CustomData.ps1 ;powershell C:\\AzureData\\CustomData.ps1;"
    } 
  SETTINGS
}
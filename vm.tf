data "http" "myip" {
  url = "http://ifconfig.me"
}

data "azurerm_subnet" "my_subnet" {
  resource_group_name   = var.rg_name
  virtual_network_name  = var.vnet_name
  name                  = var.subnet_name
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "nsg-${var.vm_name}"
  location            = var.location
  resource_group_name = var.rg_name

  security_rule {
      name                       = "SSH"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
      name                       = "SSH_external"
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = "${chomp(data.http.myip.response_body)}/32"
      destination_address_prefix = "VirtualNetwork"
  }

  tags = merge(
    {
      name        = "nsg-${var.vm_name}"
    },
    var.common_tags
  )
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.vm_name}-public-ip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Dynamic"
}


resource "azurerm_network_interface" "vm_nic" {
  name                      = "nic-${var.vm_name}"
  location                  = var.location
  resource_group_name       = var.rg_name

  ip_configuration {
      name                          = "nic-${var.vm_name}-config"
      subnet_id                     = data.azurerm_subnet.my_subnet.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }

  tags = merge(
    {
      name        = "nic-${var.vm_name}"
    },
    var.common_tags
  )
}

resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.rg_name
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]
  size                  = "Standard_B1ls"

  os_disk {
      name                  = "osdisk-${var.vm_name}"
      caching               = "ReadOnly"
      storage_account_type  = "StandardSSD_LRS"
      disk_size_gb          = 30
  }

  source_image_reference {
      publisher = "Oracle"
      offer     = "Oracle-Linux"
      sku       = "ol79-lvm-gen2"
      version   = "latest"
  }

  computer_name                   = var.vm_name
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
      username    = var.admin_username
      public_key  = file(var.ssh_public_key_file)
  }

  tags = merge(
    {
      name        = var.vm_name
    },
    var.common_tags
  )
}
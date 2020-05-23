provider "azurerm" {
  version = "=2.0.0"
  features {}
}

# Locate the existing custom/golden image
data "azurerm_image" "search" {
  name                = var.image_name
  resource_group_name = "Hashi-Environment-Automation"  #var.resource_group_name""
}

output "image_id" {
  value = data.azurerm_image.search.id
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.resource_prefix}-network5"
  address_space       = ["10.0.0.0/16"]
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}



resource "azurerm_public_ip" "static" {
  name                = "${var.resource_prefix}-public-ip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.resource_prefix}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${var.resource_prefix}-ip-config"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.static.id
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.resource_prefix}-vm"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = data.azurerm_image.search.id
  }

  storage_os_disk {
    name              = "${var.resource_prefix}-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
}  

  os_profile {
    computer_name  = "rbstesthost"
    admin_username = "scott"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys{
      key_data = var.ssh_public_key
      path= var.ssh_public_key_path
    }
  }
  tags = {
    environment = "dev"
    chargeback-code = "abc123"
  }
}
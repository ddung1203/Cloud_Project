resource "random_pet" "rg-name" {
  prefix    = var.resource_group_name_prefix
}
resource "azurerm_resource_group" "rg" {
  name      = random_pet.rg-name.id
  location  = var.resource_group_location
}
# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create public subnet
resource "azurerm_subnet" "pubsubnet" {
  name                 = "pubsubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Create private1 Subnet
resource "azurerm_subnet" "private1_subnet" {
  name                 = "prisubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes     = ["10.0.3.0/24"]
  service_endpoints    = ["Microsoft.Sql"]
}
# Create public IPs
resource "azurerm_public_ip" "pub_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
# Create private1 IPs
resource "azurerm_public_ip" "private1_ip" {
  name                = "myPrivateIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
# Create Network Security Group and rule public1
resource "azurerm_network_security_group" "pub1" {
  name                = "public1SecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "pub_sg" {
  network_interface_id      = azurerm_network_interface.pubnic.id
  network_security_group_id = azurerm_network_security_group.pub1.id
}
#Create Network Security Group and rule private1
resource "azurerm_network_security_group" "private1" {
  name                = "private1SecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

	security_rule {
    name                       = "SSH"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "private1_sg" {
  network_interface_id      = azurerm_network_interface.private1nic.id
  network_security_group_id = azurerm_network_security_group.private1.id
}
# Create network interface  pub1
resource "azurerm_network_interface" "pubnic" {
  name                = "pubNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.pubsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pub_ip.id
  }
}
# Create network interface  private1
resource "azurerm_network_interface" "private1nic" {
  name                = "private1NIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "priv1_ipconfig"
    subnet_id                     = azurerm_subnet.private1_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.private1_ip.id
  }
}
# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 8
}
# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
# Create (and display) an SSH key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Create bastion virtual machine
resource "azurerm_linux_virtual_machine" "bastionmvm" {
  name                  = "bastionVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.pubnic.id]
  size                  = "Standard_DS1_v2"
  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  computer_name                   = "bastion"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
}
# Create wp virtual machine
resource "azurerm_linux_virtual_machine" "wp" {
  name                  = "wpVM"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.private1nic.id]
  size                  = "Standard_DS1_v2"
  os_disk {
    name                 = "mywpDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  computer_name                   = "wp"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
  }
}
# Create Mariadb-server
resource "azurerm_mariadb_server" "maria" {
  name                         = "jeonj-mariadb-server-7"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  administrator_login          = "adminuser"
  administrator_login_password = "dkagh1234."
  version                      = "10.3"
  ssl_enforcement_enabled      = false
  sku_name = "GP_Gen5_2"
}
resource "azurerm_mariadb_database" "myDatabase-7" {
  name                = "wordpress"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mariadb_server.maria.name
  charset             = "utf8"
  collation           = "utf8_general_ci"
}
resource "azurerm_mariadb_virtual_network_rule" "mariaVnetRule" {
  name                = "mariadb-vnet-rule"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mariadb_server.maria.name
  subnet_id           = azurerm_subnet.private1_subnet.id
}
resource "azurerm_mariadb_firewall_rule" "mariaFwRule" {
  name                = "mriadb-fw-rule"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mariadb_server.maria.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# resource "null_resource" "wpVM_setting" {
# 	provisioner "local-exec" {
# 		command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/vars/inven.ini ansible/test.yaml -b"
# 	}
# 	depends_on = [
# 		null_resource.wpVM_ip_address
# 	]
# }
# ansible-playbook -i ansible/vars/inven.ini ansible/test.yaml -b
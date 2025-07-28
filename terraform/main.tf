# main.tf

# Configure the AzureRM Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" 
    }
  }
  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features = {}

  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}


# 1. Resource Group named Main_rg
resource "azurerm_resource_group" "main_rg" {
  name     = var.resource_group_name
  location = var.location
}

# 2. Virtual Network (VNet)
resource "azurerm_virtual_network" "main_vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
}

# 3. Subnet
resource "azurerm_subnet" "main_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 4. Network Security Group (NSG)
resource "azurerm_network_security_group" "main_nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name

  # Rule for SSH access
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*" # IMPORTANT: For production, limit this to your specific IP
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Rule for standard HTTP web traffic
  security_rule {
    name                       = "HTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Rule for all custom application ports
  security_rule {
    name                       = "CustomAppPorts"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    # All application ports:
    # 4000 (Client UI)
    # 7000 (Transaction Generation API)
    # 7002 (Data Analyser Service)
    # 5601 (Kibana UI)
    # 9200 (Elasticsearch HTTP API)
    # 9600 (Logstash)
    # 9092 (Kafka - if external clients connect)
    # 8080, 5000 (from your original list, assuming they are still relevant)
    destination_port_ranges    = ["4000", "7000", "7002", "5601", "9200", "9600", "9092", "8080", "5000"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# 5. Public IP Address
resource "azurerm_public_ip" "main_public_ip" {
  name                = "${var.prefix}-public-ip"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # Standard SKU is recommended for production workloads
}

# 6. Network Interface (NIC)
resource "azurerm_network_interface" "main_nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main_public_ip.id
  }
}
resource "azurerm_network_interface_security_group_association" "main_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.main_nic.id
  network_security_group_id = azurerm_network_security_group.main_nsg.id
}

# 7. Linux Virtual Machine (VM)
resource "azurerm_linux_virtual_machine" "main_vm" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main_rg.name
  location                        = azurerm_resource_group.main_rg.location
  size                            = "Standard_B2s" # Your chosen VM size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true # Use SSH keys for security

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(var.public_key_path) # Path to your SSH public key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" # Local Redundant Storage for cost efficiency
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2" # Ubuntu 22.04 LTS Gen2
    version   = "latest"
  }

  network_interface_ids = [
    azurerm_network_interface.main_nic.id,
  ]

  # Cloud-Init Script for Docker and Docker Compose setup
  custom_data = base64encode(templatefile("${path.module}/cloud-init.tpl", {
    github_repo_url     = var.github_repo_url
    project_directory_on_vm   = var.project_directory_on_vm
    docker_compose_path = var.docker_compose_file_path # Relative path within cloned repo
    vm_admin_username   = var.vm_admin_username
  }))

  tags = {
    environment = "development"
    project     = "SSATF_DEP_AZURE"
  }
}

# Resource pour générer et mettre à jour le fichier d'inventaire Ansible
resource "null_resource" "ansible_inventory_generator" {
  # Ce provisioner s'exécutera après que la VM et son IP soient créées.
  # La dépendance implicite via l'interpolation de la variable est suffisante ici.
  depends_on = [azurerm_linux_virtual_machine.main_vm]

  # Le provisioner "local-exec" exécute une commande sur la machine locale où Terraform est exécuté.
  provisioner "local-exec" {
    # La commande va écrire le contenu du fichier inventory.ini
    # Notez l'utilisation de `../ansible/inventory.ini` pour pointer vers le bon dossier.
    command = <<EOT
      echo "[webservers]" > ../ansible/inventory.ini
      echo "azure_vm ansible_host=${azurerm_public_ip.main_public_ip.ip_address} ansible_user=${var.vm_admin_username} ansible_ssh_private_key_file=${var.public_key_path}" >> ../ansible/inventory.ini
      echo "" >> ../ansible/inventory.ini # Ligne vide pour la clarté
      echo "[all:vars]" >> ../ansible/inventory.ini
      echo "ansible_python_interpreter=/usr/bin/python3" >> ../ansible/inventory.ini
      echo "Generated Ansible inventory with IP: ${azurerm_public_ip.main_public_ip.ip_address}"
    EOT
  }
}

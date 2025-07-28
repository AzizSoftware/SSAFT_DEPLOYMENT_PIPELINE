# variables.tf

variable "prefix" {
  description = "A prefix for all resource names to ensure uniqueness."
  type        = string
  default     = "ssatf-dep-azure"
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "West Europe" # Or "North Europe" or another suitable region
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "SSATF-Microservice-RG"
}

variable "vm_admin_username" {
  description = "The username for the admin account on the VM."
  type        = string
  default     = "azureuser"
}

variable "public_key_path" {
  description = "The path to your SSH public key file."
  type        = string
  default     = "~/.ssh/id_rsa_azure_vm.pub" # Adjust if your key is named differently
}

variable "github_repo_url" {
  description = "The URL of your GitHub repository containing the microservice application."
  type        = string
  # IMPORTANT: Replace with your actual repo URL!
  default     = "https://github.com/AzizSoftware/SSAFT_DEPLOYMENT_PIPELINE.git"
}

variable "project_directory_on_vm" {
  description = "The directory where the GitHub repo will be cloned on the VM."
  type        = string
  default     = "/home/azureuser/my-microservice-app" # Matches the cloud-init script
}

variable "docker_compose_file_path" {
  description = "The relative path to your docker-compose.yml file within the cloned repository."
  type        = string
  default     = "docker-compose.yml" # Adjust if your docker-compose file is in a subdirectory
}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}


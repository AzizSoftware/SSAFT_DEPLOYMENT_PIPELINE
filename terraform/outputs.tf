# outputs.tf

output "public_ip_address" {
  description = "The public IP address of the Azure VM."
  value       = azurerm_public_ip.main_public_ip.ip_address
}

output "vm_ssh_command" {
  description = "SSH command to connect to the VM."
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.main_public_ip.ip_address} -i ${var.public_key_path}"
}

output "application_url" {
  description = "Potential URL for your application (assuming it runs on port 80)."
  value       = "http://${azurerm_public_ip.main_public_ip.ip_address}"
}
output "vm_admin_username" {
  value       = var.vm_admin_username # Expose la valeur de la variable vm_admin_username
  description = "The admin username for the Azure VM."
}

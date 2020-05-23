output "public_ip" {
  description = "Ip of new VM"
  value       = azurerm_public_ip.static.ip_address
}
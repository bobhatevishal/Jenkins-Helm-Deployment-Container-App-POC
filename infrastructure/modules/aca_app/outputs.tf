output "id" {
  value       = azurerm_container_app.app.id
}

output "fqdn" {
  value       = azurerm_container_app.app.ingress[0].fqdn
}

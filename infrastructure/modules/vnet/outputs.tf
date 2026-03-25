output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
}

output "private_subnet_ids" {
  value = [for s in azurerm_subnet.private : s.id]
}

output "public_subnet_ids" {
  value = [for s in azurerm_subnet.public : s.id]
}

output "nsg_id" {
  value       = azurerm_network_security_group.nsg.id
}

output "appgw_subnet_id" {
  value       = azurerm_subnet.appgw.id
}

output "aca_subnet_id" {
  value       = azurerm_subnet.aca.id
}

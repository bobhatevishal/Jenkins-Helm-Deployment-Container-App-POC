# Key Infrastructure Outputs

output "resource_group_name" {
  value       = module.resource_group.name
}


output "acr_login_server" {
  value       = module.acr.login_server
}

output "acr_name" {
  value       = module.acr.acr_name
}


output "vnet_id" {
  value       = module.vnet.vnet_id
}


output "appgw_subnet_id" {
  value = module.vnet.appgw_subnet_id
}

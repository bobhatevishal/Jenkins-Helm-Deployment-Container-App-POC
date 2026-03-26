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

output "aca_db_fqdn" {
  value       = module.aca_db.fqdn
  description = "The FQDN of the db Azure Container App"
}

output "aca_api_fqdn" {
  value       = module.aca_api.fqdn
  description = "The FQDN of the api Azure Container App"
}

output "aca_frontend_fqdn" {
  value       = module.aca_frontend.fqdn
  description = "The FQDN of the frontend Azure Container App"
}

output "aca_cache_fqdn" {
  value       = module.aca_cache.fqdn
  description = "The FQDN of the cache Azure Container App"
}

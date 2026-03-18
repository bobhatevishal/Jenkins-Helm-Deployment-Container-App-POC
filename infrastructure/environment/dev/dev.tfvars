# Project Settings
project_name = "helm-deployment-app"
environment  = "dev"
location     = "Canada Central"

# Networking
vnet_address_space = ["10.0.0.0/16"]

public_subnets = {
  "pub-subnet-0" = "10.0.10.0/24"
  "pub-subnet-1" = "10.0.11.0/24"
}

private_subnets = {
  "pvt-subnet-0" = "10.0.0.0/24"
}

# AKS Configuration
node_count         = 1
min_count          = 1
max_count          = 2
vm_size            = "Standard_D2s_v3"
os_disk_size_gb    = 50
kubernetes_version = null
aks_sku_tier       = "Free"
enable_oms_agent    = false
enable_azure_policy = false

# ACR Configuration
acr_sku = "Basic"

# Tags
tags = {
  owner       = "devops team"
  environment = "dev"
}

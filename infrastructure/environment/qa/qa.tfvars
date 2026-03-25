# Project Settings
project_name = "helm-deployment-app"
environment  = "qa"
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

# ACA Configuration
aca_subnet_prefix  = "10.0.30.0/24"

# ACR Configuration
acr_sku = "Standard"

# Tags
tags = {
  owner       = "devops team"
  environment = "qa"
}

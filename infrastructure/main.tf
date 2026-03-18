# Local Values
locals {
  common_tags = merge(var.tags, {
    project     = var.project_name
    managed_by  = "terraform"
    environment = var.environment
  })
}

# 1. Resource Group
module "resource_group" {
  source   = "./modules/resource_group"
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
  tags     = local.common_tags
}

# 2. Virtual Network, Subnets & NSG
module "vnet" {
  source              = "./modules/vnet"
  vnet_name           = "${var.project_name}-${var.environment}-vnet"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vnet_address_space  = var.vnet_address_space
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  tags = local.common_tags
}


# 3. Azure Container Registry
module "acr" {
  source              = "./modules/acr"
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku
  enable_oms_agent    = var.enable_oms_agent
  enable_azure_policy = var.enable_azure_policy
  tags                = local.common_tags
}

# 4. Azure Kubernetes Service
module "aks" {
  source              = "./modules/aks"
  cluster_name        = "${var.project_name}-${var.environment}-aks"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  kubernetes_version  = var.kubernetes_version
  node_count          = var.node_count
  min_count           = var.min_count
  max_count           = var.max_count
  vm_size             = var.vm_size
  sku_tier            = var.aks_sku_tier
  acr_id              = module.acr.acr_id
  subnet_ids          = module.vnet.private_subnet_ids
  appgw_subnet_id     = module.vnet.appgw_subnet_id
  tags                = local.common_tags
}
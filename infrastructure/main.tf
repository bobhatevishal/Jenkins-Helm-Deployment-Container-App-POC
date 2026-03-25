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
  aca_subnet_prefix = var.aca_subnet_prefix

  tags = local.common_tags
}


# 3. Azure Container Registry
module "acr" {
  source              = "./modules/acr"
  name                = "${replace(var.project_name, "-", "")}${var.environment}acr"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku
  tags                = local.common_tags
}

# 4. Azure Container Apps Environment
module "aca_env" {
  source                     = "./modules/aca_env"
  name                       = "${var.project_name}-${var.environment}-env"
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  infrastructure_subnet_id   = module.vnet.aca_subnet_id
  tags                       = local.common_tags
}

# 5. Azure Container App
module "aca_app" {
  source                       = "./modules/aca_app"
  name                         = "${var.project_name}-${var.environment}-app"
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  container_app_environment_id = module.aca_env.id
  acr_id                       = module.acr.acr_id
  registry_server              = module.acr.login_server
  tags                         = local.common_tags
}

# Log Analytics Workspace (for AKS monitoring)
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "${var.cluster_name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = replace(var.cluster_name, "/[^a-zA-Z0-9-]/", "")
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier
  tags                = var.tags

  default_node_pool {
    name                 = "system"
    vm_size              = var.vm_size
    vnet_subnet_id       = var.subnet_ids[0]
    auto_scaling_enabled = true
    node_count           = var.node_count
    min_count            = var.min_count
    max_count            = var.max_count
    os_disk_size_gb      = var.os_disk_size_gb
    type                 = "VirtualMachineScaleSets"

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = lookup(var.tags, "environment", "production")
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  dynamic "oms_agent" {
    for_each = var.enable_oms_agent ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
    }
  }

  ingress_application_gateway {
    subnet_id = var.appgw_subnet_id
  }

  azure_policy_enabled = var.enable_azure_policy

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count, # Ignore count changes from auto-scaler
    ]
  }
}


# ACR Pull Role Assignment
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}





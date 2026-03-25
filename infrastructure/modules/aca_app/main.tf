resource "azurerm_user_assigned_identity" "aca_identity" {
  name                = "${var.name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aca_identity.principal_id
}

resource "azurerm_container_app" "app" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aca_identity.id]
  }

  registry {
    server   = var.registry_server
    identity = azurerm_user_assigned_identity.aca_identity.id
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = var.container_name
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      liveness_probe {
        port      = var.container_port
        transport = "HTTP"
        path      = "/"
      }

      readiness_probe {
        port      = var.container_port
        transport = "HTTP"
        path      = "/"
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # KEDA Scaling rule
    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = 10
    }
  }

  depends_on = [
    azurerm_role_assignment.acr_pull
  ]

  lifecycle {
    ignore_changes = [
      template[0].container[0].image
    ]
  }
}

resource "azurerm_container_app_environment" "task_manager" {
  count                    = var.existing_container_app_environment_name == null ? 1 : 0
  name                     = local.container_apps_env_name
  location                 = local.container_apps_location
  resource_group_name      = data.azurerm_resource_group.task_manager_rg.name
  infrastructure_subnet_id = local.container_apps_use_vnet ? azurerm_subnet.container_apps.id : null
}

resource "azurerm_container_app" "task_manager" {
  name                         = "task-manager-app"
  container_app_environment_id = local.container_apps_env_id
  resource_group_name          = data.azurerm_resource_group.task_manager_rg.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  secret {
    name  = "cosmos-connection-string"
    value = azurerm_cosmosdb_account.db.primary_mongodb_connection_string
  }

  secret {
    name  = "acr-admin-password"
    value = azurerm_container_registry.task_manager_acr.admin_password
  }

  template {
    container {
      name   = "task-manager"
      image  = "${azurerm_container_registry.task_manager_acr.login_server}/task-manager:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name        = "COSMOS_CONNECTION_STRING"
        secret_name = "cosmos-connection-string"
      }

      env {
        name  = "COSMOS_DATABASE_NAME"
        value = var.cosmos_database_name
      }

      env {
        name  = "COSMOS_COLLECTION_NAME"
        value = var.cosmos_collection_name
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  #registry i am using to pull container images
  registry {
    server               = azurerm_container_registry.task_manager_acr.login_server
    username             = azurerm_container_registry.task_manager_acr.admin_username
    password_secret_name = "acr-admin-password"
  }
}

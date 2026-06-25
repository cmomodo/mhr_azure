data "azurerm_resource_group" "task_manager_rg" {
  name = var.existing_resource_group_name
}

locals {
  resource_group_location = data.azurerm_resource_group.task_manager_rg.location
  cosmos_location         = coalesce(var.cosmos_location, local.resource_group_location)
  container_apps_location = coalesce(var.container_apps_location, local.resource_group_location)
  container_apps_use_vnet = lower(local.container_apps_location) == lower(local.resource_group_location)
  container_apps_env_name = "task-manager-cae-${replace(lower(local.container_apps_location), " ", "")}"
  container_apps_env_id   = var.existing_container_app_environment_name != null ? data.azurerm_container_app_environment.task_manager[0].id : azurerm_container_app_environment.task_manager[0].id
}

data "azurerm_container_app_environment" "task_manager" {
  count               = var.existing_container_app_environment_name != null ? 1 : 0
  name                = var.existing_container_app_environment_name
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name
}

provider "azurerm" {
  features {}
}

resource "azurerm_container_registry" "example" {
  name                  = "exampleacr"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  sku                   = "Premium"
  data_endpoint_enabled = true
}
resource "azurerm_container_registry_scope_map" "example" {
  name                    = "examplescopemap"
  container_registry_name = azurerm_container_registry.example.name
  resource_group_name     = azurerm_container_registry.example.resource_group_name
  actions = [
    "repositories/hello-world/content/delete",
    "repositories/hello-world/content/read",
    "repositories/hello-world/content/write",
    "repositories/hello-world/metadata/read",
    "repositories/hello-world/metadata/write",
    "gateway/examplecr/config/read",
    "gateway/examplecr/config/write",
    "gateway/examplecr/message/read",
    "gateway/examplecr/message/write",
  ]
}
resource "azurerm_container_registry_token" "example" {
  name                    = "exampletoken"
  container_registry_name = azurerm_container_registry.example.name
  resource_group_name     = azurerm_container_registry.example.resource_group_name
  scope_map_id            = azurerm_container_registry_scope_map.example.id
}
resource "azurerm_container_connected_registry" "example" {
  name                  = "examplecr"
  container_registry_id = azurerm_container_registry.example.id
  sync_token_id         = azurerm_container_registry_token.example.id
}

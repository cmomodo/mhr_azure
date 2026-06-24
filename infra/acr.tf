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



resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.example.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.example.identity[0].principal_id
}

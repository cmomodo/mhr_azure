resource "azurerm_container_registry" "task_manager_acr" {
  name                          = var.acr_name
  resource_group_name           = data.azurerm_resource_group.task_manager_rg.name
  location                      = data.azurerm_resource_group.task_manager_rg.location
  sku                           = "Premium"
  admin_enabled                 = true
  data_endpoint_enabled         = true
  public_network_access_enabled = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                  = "task-manager-acr-vnet-link"
  resource_group_name   = data.azurerm_resource_group.task_manager_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.task_manager_vnet.id
}

resource "azurerm_private_endpoint" "acr" {
  name                = "task-manager-acr-pe"
  location            = data.azurerm_resource_group.task_manager_rg.location
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "task-manager-acr-psc"
    private_connection_resource_id = azurerm_container_registry.task_manager_acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "task-manager-acr-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr.id]
  }
}

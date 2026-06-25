resource "azurerm_public_ip" "application_gateway" {
  name                = "${var.application_gateway_name}-pip"
  location            = data.azurerm_resource_group.task_manager_rg.location
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "task_manager" {
  name                = var.application_gateway_name
  location            = data.azurerm_resource_group.task_manager_rg.location
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name

  sku {
    name     = var.application_gateway_sku_name
    tier     = var.application_gateway_sku_tier
    capacity = var.application_gateway_capacity
  }

  gateway_ip_configuration {
    name      = "task-manager-agw-ip-config"
    subnet_id = azurerm_subnet.application_gateway.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.application_gateway.id
  }

  backend_address_pool {
    name  = "container-app-backend-pool"
    fqdns = [azurerm_container_app.task_manager.latest_revision_fqdn]
  }

  backend_http_settings {
    name                                = "container-app-backend-settings"
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "container-app-health-probe"
  }

  probe {
    name                                      = "container-app-health-probe"
    protocol                                  = "Https"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "public-http-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "container-app-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "public-http-listener"
    backend_address_pool_name  = "container-app-backend-pool"
    backend_http_settings_name = "container-app-backend-settings"
    priority                   = 100
  }
}

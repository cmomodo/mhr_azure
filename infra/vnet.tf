resource "azurerm_network_security_group" "task_manager" {
  name                = "task-manager-nsg"
  location            = data.azurerm_resource_group.task_manager_rg.location
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name
}

resource "azurerm_virtual_network" "task_manager_vnet" {
  name                = "task-manager-vnet"
  location            = data.azurerm_resource_group.task_manager_rg.location
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name
  address_space       = ["10.10.0.0/16"]

  tags = {
    environment = "production"
  }
}

resource "azurerm_subnet" "private_endpoints" {
  name                              = "private-endpoints-subnet"
  resource_group_name               = data.azurerm_resource_group.task_manager_rg.name
  virtual_network_name              = azurerm_virtual_network.task_manager_vnet.name
  address_prefixes                  = ["10.10.1.0/24"]
  private_endpoint_network_policies = "Disabled"
}

resource "azurerm_subnet" "container_apps" {
  name                 = "container-apps-subnet"
  resource_group_name  = data.azurerm_resource_group.task_manager_rg.name
  virtual_network_name = azurerm_virtual_network.task_manager_vnet.name
  address_prefixes     = ["10.10.2.0/23"]

  delegation {
    name = "container-apps-delegation"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "container_apps" {
  subnet_id                 = azurerm_subnet.container_apps.id
  network_security_group_id = azurerm_network_security_group.task_manager.id
}

resource "azurerm_subnet" "application_gateway" {
  name                 = "application-gateway-subnet"
  resource_group_name  = data.azurerm_resource_group.task_manager_rg.name
  virtual_network_name = azurerm_virtual_network.task_manager_vnet.name
  address_prefixes     = ["10.10.4.0/24"]
}

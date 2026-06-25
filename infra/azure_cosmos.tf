resource "azurerm_cosmosdb_account" "db" {
  name                = var.cosmos_account_name
  location            = local.cosmos_location
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  mongo_server_version          = "4.2"
  public_network_access_enabled = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = local.cosmos_location
    failover_priority = 0
    zone_redundant    = false
  }
}

resource "azurerm_cosmosdb_mongo_database" "tasks" {
  name                = var.cosmos_database_name
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name
  account_name        = azurerm_cosmosdb_account.db.name
}

resource "azurerm_cosmosdb_mongo_collection" "tasks" {
  name                = var.cosmos_collection_name
  resource_group_name = data.azurerm_resource_group.task_manager_rg.name
  account_name        = azurerm_cosmosdb_account.db.name
  database_name       = azurerm_cosmosdb_mongo_database.tasks.name

  index {
    keys = ["_id"]
  }

  index {
    keys = ["id"]
  }
}

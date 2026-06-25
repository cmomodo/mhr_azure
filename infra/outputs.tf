output "cosmos_account_name" {
  description = "Cosmos DB account name."
  value       = azurerm_cosmosdb_account.db.name
}

output "cosmos_database_name" {
  description = "Cosmos DB MongoDB database name."
  value       = azurerm_cosmosdb_mongo_database.tasks.name
}

output "cosmos_collection_name" {
  description = "Cosmos DB MongoDB collection name."
  value       = azurerm_cosmosdb_mongo_collection.tasks.name
}

output "cosmos_mongodb_connection_string" {
  description = "Primary MongoDB connection string for the Cosmos DB account."
  value       = azurerm_cosmosdb_account.db.primary_mongodb_connection_string
  sensitive   = true
}

output "container_app_fqdn" {
  description = "FQDN of the deployed Container App."
  value       = azurerm_container_app.task_manager.latest_revision_fqdn
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Azure Application Gateway."
  value       = azurerm_public_ip.application_gateway.ip_address
}

output "application_gateway_frontend_url" {
  description = "HTTP URL exposed by the Azure Application Gateway."
  value       = "http://${azurerm_public_ip.application_gateway.ip_address}"
}

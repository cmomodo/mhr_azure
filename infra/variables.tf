variable "subscription_id" {
  description = "Azure subscription ID for the deployment."
  type        = string
  default     = "a3ea6416-7936-4e88-8568-4d67676f0cbd"
}

variable "acr_name" {
  description = "Globally unique Azure Container Registry name (lowercase alphanumeric, 5-50 chars)."
  type        = string
  default     = "taskmanagermhracr"
}

variable "existing_resource_group_name" {
  description = "Name of the pre-existing Azure resource group to deploy into."
  type        = string
  default     = "27_state_file"
}

variable "cosmos_account_name" {
  description = "Globally unique Cosmos DB account name (lowercase, 3-44 chars). Change if already taken."
  type        = string
  default     = "taskmanagercosmosmhr02"
}

variable "cosmos_location" {
  description = "Azure region for Cosmos DB. East US frequently rejects new Cosmos accounts due to capacity; eastus2 is used as a low-latency alternative. Defaults to the resource group location when null."
  type        = string
  default     = "eastus2"
}

variable "cosmos_database_name" {
  description = "MongoDB database name for task storage."
  type        = string
  default     = "taskdb"
}

variable "cosmos_collection_name" {
  description = "MongoDB collection name for tasks."
  type        = string
  default     = "tasks"
}

variable "application_gateway_name" {
  description = "Name of the Azure Application Gateway."
  type        = string
  default     = "task-manager-agw"
}

variable "application_gateway_sku_name" {
  description = "SKU name for the Azure Application Gateway."
  type        = string
  default     = "Standard_v2"
}

variable "application_gateway_sku_tier" {
  description = "SKU tier for the Azure Application Gateway."
  type        = string
  default     = "Standard_v2"
}

variable "application_gateway_capacity" {
  description = "Instance count for the Azure Application Gateway."
  type        = number
  default     = 1
}

variable "existing_container_app_environment_name" {
  description = "Name of an existing Azure Container Apps environment to reuse. Leave null to create one with Terraform."
  type        = string
  default     = null
}

variable "container_apps_location" {
  description = "Azure region for the Container Apps environment. Defaults to eastus2 to avoid eastus capacity issues."
  type        = string
  default     = "eastus2"
}

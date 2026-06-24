terraform {
  backend "azurerm" {
    resource_group_name  = "27_state_file"
    storage_account_name = "mhstate01"
    container_name       = "tfstate"
    key                  = "project-name.tfstate"
  }
}

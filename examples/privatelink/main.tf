terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.13.0"

  location         = var.location
  enable_telemetry = var.enable_telemetry
  is_recommended   = true
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/avm-utl-naming/azure"
  version = "0.2.0"
}

# This is required for resource modules
resource "azapi_resource" "resource_group" {
  location               = module.regions.regions[random_integer.region_index.result].name
  name                   = module.naming.resource_group.name_unique
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  response_export_values = []
}

# The Log Analytics workspace that Application Insights sends its data to.
resource "azapi_resource" "log_analytics_workspace" {
  location  = azapi_resource.resource_group.location
  name      = module.naming.log_analytics_workspace.name_unique
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.OperationalInsights/workspaces@2025-07-01"
  body = {
    properties = {
      retentionInDays = 30
      sku = {
        name = "PerGB2018"
      }
    }
  }
  response_export_values = []
}

resource "azapi_resource" "private_link_scope" {
  location  = "global"
  name      = "privatelink.scope"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Insights/privateLinkScopes@2021-09-01"
  body = {
    properties = {
      accessModeSettings = {
        ingestionAccessMode = "Open"
        queryAccessMode     = "Open"
      }
    }
  }
  response_export_values = []
}

# This is the module call
module "test" {
  source = "../.."
  providers = {
    azapi = azapi
  }

  location                      = azapi_resource.resource_group.location
  name                          = module.naming.application_insights.name_unique
  parent_id                     = azapi_resource.resource_group.id
  workspace_id                  = azapi_resource.log_analytics_workspace.id
  enable_telemetry              = var.enable_telemetry # see variables.tf
  internet_ingestion_enabled    = false
  internet_query_enabled        = false
  local_authentication_disabled = true
  monitor_private_link_scope = {
    ampls_01 = {
      resource_id = azapi_resource.private_link_scope.id
    }
  }
}

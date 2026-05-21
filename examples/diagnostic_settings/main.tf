terraform {
  required_version = "~> 1.3"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">=2.9.0, < 3.0.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.71, < 5.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
provider "azurerm" {
  features {}
}

provider "azapi" {}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  is_recommended = true
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.3"
}

resource "azapi_resource" "resource_group" {
  location               = module.regions.regions[random_integer.region_index.result].name
  name                   = module.naming.resource_group.name_unique
  type                   = "Microsoft.Resources/resourceGroups@2024-03-01"
  response_export_values = []
}

#Log Analytics Workspace for diagnostic settings. Required for workspace-based diagnostic settings.
resource "azapi_resource" "log_insights" {
  location  = azapi_resource.resource_group.location
  name      = "${module.naming.log_analytics_workspace.name_unique}-ai"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.OperationalInsights/workspaces@2025-07-01"
  body = {
    properties = {
      sku = {
        name = "PerGB2018"
      }
      retentionInDays = 30
    }
  }
  response_export_values = []
}

resource "azapi_resource" "log_diagnostic" {
  location  = azapi_resource.resource_group.location
  name      = "${module.naming.log_analytics_workspace.name_unique}-diag"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.OperationalInsights/workspaces@2025-07-01"
  body = {
    properties = {
      sku = {
        name = "PerGB2018"
      }
      retentionInDays = 30
      features = {
        disableLocalAuth = true
      }
    }
  }
  response_export_values = []
}


# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../.."

  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location            = azapi_resource.resource_group.location
  name                = module.naming.application_insights.name_unique
  resource_group_name = azapi_resource.resource_group.name
  workspace_id        = azapi_resource.log_insights.id
  diagnostic_settings = {
    default = {
      name                  = "diag-${module.naming.application_insights.name_unique}"
      workspace_resource_id = azapi_resource.log_diagnostic.id
      metrics = [
        {
          category = "AllMetrics"
          enabled  = true
        }
      ]
      logs = [
        {
          category = "AppAvailabilityResults"
          enabled  = true
        },
        {
          category = "AppEvents"
          enabled  = false
        },
        {
          category = "AppExceptions"
          enabled  = false
        },
        {
          category = "AppMetrics"
          enabled  = true
        },
        {
          category = "AppPerformanceCounters"
          enabled  = true
        },
        {
          category = "AppRequests"
          enabled  = true
        },
        {
          category = "AppSystemEvents"
          enabled  = false
        },
        {
          category = "AppTraces"
          enabled  = true
        },
        {
          category = "AppBrowserTimings"
          enabled  = false
        },
        {
          category = "AppDependencies"
          enabled  = false
        },
        {
          category = "AppPageViews"
          enabled  = false
        },
        {
          category = "OTelResources"
          enabled  = false
        }
      ]
    }
  }
  enable_telemetry = var.enable_telemetry # see variables.tf
}

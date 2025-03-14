<!-- BEGIN_TF_DOCS -->
# Privatelink

This deploys the module with local authentication disabled, public internet ingest, query disabled with private link.

```hcl
terraform {
  required_version = "~> 1.3"
  required_providers {
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


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
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
  version = ">= 0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}


#Log Analytics Workspace for diagnostic settings. Required for workspace-based diagnostic settings.
resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
}


# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../.."
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location                      = azurerm_resource_group.this.location
  name                          = module.naming.application_insights.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  workspace_id                  = azurerm_log_analytics_workspace.this.id
  enable_telemetry              = var.enable_telemetry # see variables.tf
  local_authentication_disabled = true
  internet_ingestion_enabled    = false
  internet_query_enabled        = false
}

resource "azurerm_monitor_private_link_scope" "this" {
  name                = "privatelink.scope"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_monitor_private_link_scoped_service" "this" {
  linked_resource_id  = module.test.resource_id
  name                = "privatelinkscopedservice.appinsights"
  resource_group_name = azurerm_resource_group.this.name
  scope_name          = azurerm_monitor_private_link_scope.this.name
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.3)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>=3.71, < 5.0.0)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_monitor_private_link_scope.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scope) (resource)
- [azurerm_monitor_private_link_scoped_service.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scoped_service) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: >= 0.3.0

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: ~> 0.3

### <a name="module_test"></a> [test](#module\_test)

Source: ../..

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
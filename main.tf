

resource "azurerm_application_insights" "this" {
  application_type                      = var.application_type
  location                              = var.location
  name                                  = var.name
  resource_group_name                   = var.resource_group_name
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
  disable_ip_masking                    = var.disable_ip_masking
  force_customer_storage_for_profiler   = var.force_customer_storage_for_profiler
  internet_ingestion_enabled            = var.internet_ingestion_enabled
  internet_query_enabled                = var.internet_query_enabled
  local_authentication_disabled         = var.local_authentication_disabled
  retention_in_days                     = var.retention_in_days
  sampling_percentage                   = var.sampling_percentage
  tags                                  = var.tags
  workspace_id                          = var.workspace_id
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_application_insights.this.id
}

resource "azapi_resource" "monitor_private_link_scope" {
  for_each = var.monitor_private_link_scope

  type = "Microsoft.Insights/privateLinkScopes/scopedResources@2023-06-01-preview"
  body = {
    properties = {
      linkedResourceId = azurerm_application_insights.this.id
    }
  }
  ignore_casing = true
  name          = each.value.name != null ? each.value.name : azurerm_application_insights.this.name
  parent_id     = each.value.resource_id
}

resource "azapi_resource" "linked_storage_account" {
  for_each = var.linked_storage_account

  type = "microsoft.insights/components/linkedStorageAccounts@2020-03-01-preview"
  body = {
    properties = {
      linkedStorageAccount = each.value.resource_id
    }
  }
  ignore_casing = true
  name          = "serviceprofiler"
  parent_id     = azurerm_application_insights.this.id
}

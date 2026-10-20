output "app_id" {
  description = "App ID of the Application Insights"
  sensitive   = true
  value       = terraform_data.application_insights_assigned_values.output.app_id
}

output "connection_string" {
  description = "Connection String of the Application Insights"
  sensitive   = true
  value       = terraform_data.application_insights_assigned_values.output.connection_string
}

output "instrumentation_key" {
  description = "Instrumentation Key of the Application Insights"
  sensitive   = true
  value       = terraform_data.application_insights_assigned_values.output.instrumentation_key
}

output "name" {
  description = "Name of the Application Insights"
  value       = azapi_resource.this.name
}

output "resource" {
  description = <<DESCRIPTION
Deprecated, use the other outputs instead. This output will be removed in a future release.

The attributes of the former `azurerm_application_insights` resource that map to this module's inputs, plus `id` and `app_id`. It does not include `connection_string` or `instrumentation_key`; use those outputs instead.
DESCRIPTION
  value = {
    id                                    = azapi_resource.this.id
    name                                  = azapi_resource.this.name
    location                              = azapi_resource.this.location
    resource_group_name                   = local.resource_group_name
    application_type                      = var.application_type
    app_id                                = terraform_data.application_insights_assigned_values.output.app_id
    daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
    daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
    disable_ip_masking                    = var.disable_ip_masking
    force_customer_storage_for_profiler   = var.force_customer_storage_for_profiler
    internet_ingestion_enabled            = var.internet_ingestion_enabled
    internet_query_enabled                = var.internet_query_enabled
    local_authentication_disabled         = var.local_authentication_disabled
    retention_in_days                     = var.retention_in_days
    sampling_percentage                   = var.sampling_percentage
    tags                                  = azapi_resource.this.tags
    workspace_id                          = var.workspace_id
  }
}

output "resource_id" {
  description = "The ID of the Application Insights"
  value       = azapi_resource.this.id
}

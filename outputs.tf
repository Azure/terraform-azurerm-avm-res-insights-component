output "app_id" {
  description = "App ID of the Application Insights"
  sensitive   = true
  value       = azurerm_application_insights.this.app_id
}

output "connection_string" {
  description = "Connection String of the Application Insights"
  sensitive   = true
  value       = azurerm_application_insights.this.connection_string
}

output "instrumentation_key" {
  description = "Instrumentation Key of the Application Insights"
  value       = azurerm_application_insights.this.instrumentation_key
}

output "name" {
  description = "Name of the Application Insights"
  value       = azurerm_application_insights.this.name
}

# Guidance change to prohibit output of resource as an object. This will be a breaking change next major release.
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = "This is the full output for the resource."
  value       = azurerm_application_insights.this
}

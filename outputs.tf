output "name" {
  description = "Name of the Application Insights"
  value       = azurerm_application_insights.this.name
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = "This is the full output for the resource."
  value       = azurerm_application_insights.this
}

output "resource_id" {
  description = "The ID of the Application Insights"
  value       = azurerm_application_insights.this.id
}

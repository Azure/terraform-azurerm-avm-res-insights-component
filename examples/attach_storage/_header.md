# Attached storage

Requires granting the Storage Blob Data Contributor role to the Microsoft Entra application Diagnostic Services Trusted Storage Access.

  ```hcl
  data "azuread_service_principal" "this" {
    display_name = "Diagnostic Services Trusted Storage Access"
  }

  resource "azurerm_role_assignment" "this" {
    principal_id         = data.azuread_service_principal.this.object_id
    scope                = azurerm_storage_account.this.id
    role_definition_name = "Storage Blob Data Contributor"
  }
  ```

This deploys the module with force customer storage for profiler enabled, attached storage for the service profiler.

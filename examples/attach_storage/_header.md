# Attached storage

This deploys the module with force customer storage for profiler enabled, attached storage for the service profiler.

The profiler also needs the Microsoft Entra application Diagnostic Services Trusted Storage Access to have the Storage Blob Data Contributor role on the storage account. Find its object ID with `az ad sp list --display-name "Diagnostic Services Trusted Storage Access" --query "[0].id" --output tsv`, and assign the role, for example:

```hcl
resource "azapi_resource" "profiler_storage_access" {
  name      = uuidv5("url", "${azapi_resource.storage_account.id}/profiler-storage-access")
  parent_id = azapi_resource.storage_account.id
  type      = "Microsoft.Authorization/roleAssignments@2022-04-01"
  body = {
    properties = {
      principalId      = var.diagnostic_services_trusted_storage_access_object_id
      principalType    = "ServicePrincipal"
      roleDefinitionId = "${azapi_resource.resource_group.parent_id}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe"
    }
  }
  response_export_values = []
}
```

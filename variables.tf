variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this resource."

  validation {
    condition     = can(regex("^[A-Za-z0-9._()-]{1,254}[A-Za-z0-9_()-]$", var.name))
    error_message = "The name must be between 5 and 50 characters long and can only contain lowercase letters and numbers."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "workspace_id" {
  type        = string
  description = "(Required) The ID of the Log Analytics workspace to send data to. AzureRm supports classic; however, Azure has deprecated it, thus it's required"
  nullable    = false
}

variable "application_type" {
  type        = string
  default     = "web"
  description = "(Required) The type of the application. Possible values are 'web', 'ios', 'java', 'phone', 'MobileCenter', 'other', 'store'."

  validation {
    condition     = contains(["ios", "java", "MobileCenter", "other", "phone", "store", "web"], var.application_type)
    error_message = "Invalid value for replication type. Valid options are 'web', 'ios', 'java', 'phone', 'MobileCenter', 'other', 'store'."
  }
}

# Optional Variables
variable "daily_data_cap_in_gb" {
  type        = number
  default     = 100
  description = "(Optional) The daily data cap in GB. 0 means unlimited."
}

variable "daily_data_cap_notifications_disabled" {
  type        = bool
  default     = false
  description = "(Optional) Disables the daily data cap notifications."
}

variable "disable_ip_masking" {
  type        = bool
  default     = false
  description = "(Optional) Disables IP masking. Defaults to false. For more information see <https://aka.ms/avm/ipmasking>."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "force_customer_storage_for_profiler" {
  type        = bool
  default     = false
  description = "(Optional) Forces customer storage for profiler. Defaults to false."
}

variable "internet_ingestion_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Enables internet ingestion. Defaults to true."
}

variable "internet_query_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Enables internet query. Defaults to true."
}

variable "linked_storage_account" {
  type = map(object({
    resource_id = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  Linked storage account configuration for the Application Insights profiler.
    - `resource_id`: The resource ID of the storage account.

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
DESCRIPTION
}

variable "local_authentication_disabled" {
  type        = bool
  default     = false
  description = "(Optional) Disables local authentication. Defaults to false."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:
  
  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:
  
  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "monitor_private_link_scope" {
  type = map(object({
    resource_id = optional(string, null)
    name        = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  Monitor private link scope to connect the Application Insights resource to.
    - `resource_id`: The resource ID of the monitor private link scope.
    - `name`: The name of the scoped resource. Defaults to the Application Insights resource name.
DESCRIPTION
}

variable "retention_in_days" {
  type        = number
  default     = 90
  description = "(Optional) The retention period in days. 0 means unlimited."
}

variable "sampling_percentage" {
  type        = number
  default     = 100
  description = "(Optional) The sampling percentage. 100 means all."
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

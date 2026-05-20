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
  description = "(Required) The type of the application. Possible values are 'web', 'ios', 'java', 'phone', 'MobileCenter', 'Node.JS', 'other', 'store'."

  validation {
    condition     = contains(["ios", "java", "MobileCenter", "Node.JS", "other", "phone", "store", "web"], var.application_type)
    error_message = "Invalid value for application type. Valid options are 'web', 'ios', 'java', 'phone', 'MobileCenter', 'Node.JS', 'other', 'store'."
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

variable "diagnostic_settings" {
  type = map(object({
    name = optional(string, null)
    logs = optional(set(object({
      category       = optional(string, null)
      category_group = optional(string, null)
      enabled        = optional(bool, true)
      retention_policy = optional(object({
        days    = optional(number, 0)
        enabled = optional(bool, false)
      }), {})
    })), [])
    metrics = optional(set(object({
      category = optional(string, null)
      enabled  = optional(bool, true)
      retention_policy = optional(object({
        days    = optional(number, 0)
        enabled = optional(bool, false)
      }), {})
    })), [])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of diagnostic settings to create on the Application Insights component. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `logs` - (Optional) A set of log categories or category groups to send to the destination. If both `logs` and `metrics` are omitted or empty, the module defaults to enabling `allLogs`. If `logs` is provided and `metrics` is omitted, metrics remain unset.
  - `metrics` - (Optional) A set of metric categories to send to the destination. If both `logs` and `metrics` are omitted or empty, the module defaults to enabling `AllMetrics`. If `metrics` is provided and `logs` is omitted, logs remain unset. At this resource scope, the only supported metric category is `AllMetrics`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      alltrue([for metric in v.metrics : metric.category == null || metric.category == "AllMetrics"])
    ])
    error_message = "metrics[*].category must be `AllMetrics` or null for Application Insights diagnostic settings."
  }
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
  nullable    = false
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

  - `resource_id` - The resource ID of the storage account.
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

variable "monitor_private_link_scope" {
  type = map(object({
    resource_id           = optional(string, null)
    name                  = optional(string, null)
    kind                  = optional(string, "Resource")
    subscription_location = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  Monitor private link scope to connect the Application Insights resource to.

  - `resource_id` - The resource ID of the monitor private link scope.
  - `name` - The name of the scoped resource. Defaults to the Application Insights resource name.
  - `kind` - The kind of the scoped resource. Defaults to `Resource`. Possible values are `Resource` or `Metrics`.
  - `subscription_location` - The location of the subscription. This is required for kind `Metrics`.
  DESCRIPTION

  validation {
    condition = alltrue([
      for scope in [for scope in var.monitor_private_link_scope : scope] : (
        (scope.kind == "Resource" && scope.subscription_location == null) ||
        (scope.kind == "Metrics" && scope.subscription_location != null)
      )
    ])
    error_message = "For kind `Metrics`, subscription_location is required. For kind `Resource`, subscription_location must be null."
  }
}

variable "retention_in_days" {
  type        = number
  default     = 90
  description = "(Optional) The retention period in days. 0 means unlimited."
}

variable "retry" {
  type = object({
    error_message_regex  = optional(list(string), ["ScopeLocked"])
    interval_seconds     = optional(number, null)
    max_interval_seconds = optional(number, null)
  })
  default     = null
  description = <<DESCRIPTION
  The retry configuration for azapi resources. The following properties can be specified:

  - `error_message_regex` - (Required) A list of regular expressions to match against error messages. If any match, the request will be retried.
  - `interval_seconds` - (Optional) The base number of seconds to wait between retries. Default is `10`.
  - `max_interval_seconds` - (Optional) The maximum number of seconds to wait between retries. Default is `180`.
  DESCRIPTION
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.
- `delegated_managed_identity_resource_id` - The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created.
- `principal_type` - The type of the principal_id. Possible values are `User`, `Group` and `ServicePrincipal`. Changing this forces a new resource to be created. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
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

variable "timeouts" {
  type = object({
    create = optional(string, null)
    delete = optional(string, null)
    read   = optional(string, null)
    update = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  The timeout configuration for azapi resources. The following properties can be specified:

  - `create` - (Optional) The timeout for create operations e.g. `"30m"`, `"1h"`.
  - `delete` - (Optional) The timeout for delete operations e.g. `"30m"`, `"1h"`.
  - `read` - (Optional) The timeout for read operations e.g. `"30m"`, `"1h"`.
  - `update` - (Optional) The timeout for update operations e.g. `"30m"`, `"1h"`.
  DESCRIPTION
}

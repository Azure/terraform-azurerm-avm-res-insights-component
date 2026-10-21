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

variable "parent_id" {
  type        = string
  description = "The resource ID of the existing resource group to deploy the Application Insights component into, for example `/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/example-rg`."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id))
    error_message = "`parent_id` must be a valid resource group resource ID."
  }
}

variable "workspace_id" {
  type        = string
  description = "(Required) The resource ID of the Log Analytics workspace to send data to. Azure has retired classic Application Insights components, so a workspace is required."
  nullable    = false

  validation {
    condition     = can(provider::azapi::parse_resource_id("Microsoft.OperationalInsights/workspaces", var.workspace_id))
    error_message = "`workspace_id` must be a valid Log Analytics workspace resource ID."
  }
}

variable "application_type" {
  type        = string
  default     = "web"
  description = "(Optional) The type of the application. Possible values are 'web', 'ios', 'java', 'phone', 'MobileCenter', 'Node.JS', 'other', 'store'. Changing this replaces the Application Insights component."
  nullable    = false

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
  nullable    = false

  validation {
    condition     = var.daily_data_cap_in_gb >= 0
    error_message = "`daily_data_cap_in_gb` must not be negative."
  }
}

variable "daily_data_cap_notifications_disabled" {
  type        = bool
  default     = false
  description = "(Optional) Disables the daily data cap notifications."
  nullable    = false
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
    condition = alltrue([
      for _, v in var.diagnostic_settings : alltrue([
        for l in v.logs : (l.category != null) != (l.category_group != null)
      ])
    ])
    error_message = "Each log entry must set exactly one of `category` or `category_group`."
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
      v.workspace_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.OperationalInsights/workspaces", v.workspace_resource_id))
    ])
    error_message = "Each `workspace_resource_id` must be a valid Log Analytics workspace resource ID, or null."
  }
  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      v.storage_account_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", v.storage_account_resource_id))
    ])
    error_message = "Each `storage_account_resource_id` must be a valid storage account resource ID, or null."
  }
  validation {
    condition = alltrue([
      for _, v in var.diagnostic_settings :
      v.event_hub_authorization_rule_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.EventHub/namespaces/authorizationRules", v.event_hub_authorization_rule_resource_id))
    ])
    error_message = "Each `event_hub_authorization_rule_resource_id` must be a valid Event Hub namespace authorization rule resource ID, or null."
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
  nullable    = false
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
  nullable    = false
}

variable "ignore_body_changes" {
  type = object({
    authorization_locks                           = optional(list(string), [])
    authorization_role_assignments                = optional(list(string), [])
    insights_components                           = optional(list(string), [])
    insights_components_linked_storage_accounts   = optional(list(string), [])
    insights_components_pricing_plans             = optional(list(string), [])
    insights_diagnostic_settings                  = optional(list(string), [])
    insights_private_link_scopes_scoped_resources = optional(list(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Paths in each AzAPI resource's body whose changes are ignored, in dot notation relative to the body, for example `tags` or `properties.SamplingPercentage`. Individual list items cannot be targeted; ignore the whole list instead. Configuration at an ignored path is not sent to Azure until the path is removed, and a change to this variable takes effect only after the next apply. A non-empty list requires Terraform 1.11 or later.

- `authorization_locks` - Paths ignored on the management lock.
- `authorization_role_assignments` - Paths ignored on the role assignments.
- `insights_components` - Paths ignored on the Application Insights component.
- `insights_components_linked_storage_accounts` - Paths ignored on the profiler's linked storage account.
- `insights_components_pricing_plans` - `properties`, `properties.cap` or `properties.stopSendNotificationWhenHitCap` stop the module managing the daily data cap and its notifications. The daily data cap is managed with `azapi_update_resource`, which has no `ignore_body_changes` argument, so these properties are left out of the update instead, and Terraform 1.11 is not required for them.
- `insights_diagnostic_settings` - Paths ignored on the diagnostic settings.
- `insights_private_link_scopes_scoped_resources` - Paths ignored on the Azure Monitor private link scope connections.
DESCRIPTION
  nullable    = false
}

variable "internet_ingestion_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Enables internet ingestion. Defaults to true."
  nullable    = false
}

variable "internet_query_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Enables internet query. Defaults to true."
  nullable    = false
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
  nullable    = false

  validation {
    condition = alltrue([
      for _, v in var.linked_storage_account :
      v.resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.Storage/storageAccounts", v.resource_id))
    ])
    error_message = "Each `linked_storage_account[*].resource_id` must be a valid storage account resource ID."
  }
}

variable "local_authentication_disabled" {
  type        = bool
  default     = false
  description = "(Optional) Disables local authentication. Defaults to false."
  nullable    = false
}

variable "lock" {
  type = object({
    kind  = string
    name  = optional(string, null)
    notes = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, `lock-<name>` is used, where `<name>` is the name of the Application Insights component. Changing this forces the creation of a new resource.
- `notes` - (Optional) Notes about the lock. This value maps to `Microsoft.Authorization/locks.properties.notes`.
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
  nullable    = false

  validation {
    condition = alltrue([
      for scope in [for scope in var.monitor_private_link_scope : scope] : (
        (scope.kind == "Resource" && scope.subscription_location == null) ||
        (scope.kind == "Metrics" && scope.subscription_location != null)
      )
    ])
    error_message = "For kind `Metrics`, subscription_location is required. For kind `Resource`, subscription_location must be null."
  }
  validation {
    condition = alltrue([
      for _, v in var.monitor_private_link_scope :
      v.resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.Insights/privateLinkScopes", v.resource_id))
    ])
    error_message = "Each `monitor_private_link_scope[*].resource_id` must be a valid Azure Monitor private link scope resource ID."
  }
}

variable "resource_types" {
  type = object({
    authorization_locks                           = optional(string, "Microsoft.Authorization/locks@2020-05-01")
    authorization_role_assignments                = optional(string, "Microsoft.Authorization/roleAssignments@2022-04-01")
    insights_components                           = optional(string, "Microsoft.Insights/components@2020-02-02")
    insights_components_linked_storage_accounts   = optional(string, "microsoft.insights/components/linkedStorageAccounts@2020-03-01-preview")
    insights_components_pricing_plans             = optional(string, "microsoft.insights/components/pricingPlans@2017-10-01")
    insights_diagnostic_settings                  = optional(string, "Microsoft.Insights/diagnosticSettings@2021-05-01-preview")
    insights_private_link_scopes_scoped_resources = optional(string, "Microsoft.Insights/privateLinkScopes/scopedResources@2023-06-01-preview")
  })
  default     = {}
  description = <<DESCRIPTION
The AzAPI resource types and API versions the module uses. Override a value to use a different API version, for example in a sovereign cloud.

- `authorization_locks` - The management lock.
- `authorization_role_assignments` - The role assignments.
- `insights_components` - The Application Insights component.
- `insights_components_linked_storage_accounts` - The profiler's linked storage account. Only a preview API version exists.
- `insights_components_pricing_plans` - The pricing plan that holds the daily data cap.
- `insights_diagnostic_settings` - The diagnostic settings.
- `insights_private_link_scopes_scoped_resources` - The Azure Monitor private link scope connections. The default is a preview API version, because `kind` and `subscriptionLocation` are not in a stable one.
DESCRIPTION
  nullable    = false
}

variable "retention_in_days" {
  type        = number
  default     = 90
  description = "(Optional) The retention period in days. Possible values are `30`, `60`, `90`, `120`, `180`, `270`, `365`, `550` and `730`. Defaults to `90`."
  nullable    = false

  validation {
    condition     = contains([30, 60, 90, 120, 180, 270, 365, 550, 730], var.retention_in_days)
    error_message = "`retention_in_days` must be one of 30, 60, 90, 120, 180, 270, 365, 550 or 730."
  }
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
    name                                   = optional(string, null)
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
A map of role assignments to create on the Application Insights component. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the role assignment. If not set, a random UUID will be generated. Changing this forces the creation of a new resource.
- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false

  validation {
    condition = alltrue([
      for _, v in var.role_assignments :
      v.delegated_managed_identity_resource_id == null || can(provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", v.delegated_managed_identity_resource_id))
    ])
    error_message = "Each `role_assignments[*].delegated_managed_identity_resource_id` must be a valid user-assigned managed identity resource ID, or null."
  }
}

variable "sampling_percentage" {
  type        = number
  default     = 100
  description = "(Optional) The sampling percentage. 100 means all."
  nullable    = false

  validation {
    condition     = var.sampling_percentage >= 0 && var.sampling_percentage <= 100
    error_message = "`sampling_percentage` must be between 0 and 100."
  }
}

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

<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-insights-component

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.4, < 3.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>=3.71, < 5.0.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azapi_resource.linked_storage_account](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.monitor_private_link_scope](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_application_insights.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the this resource.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

### <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id)

Description: (Required) The ID of the Log Analytics workspace to send data to. AzureRm supports classic; however, Azure has deprecated it, thus it's required

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_application_type"></a> [application\_type](#input\_application\_type)

Description: (Required) The type of the application. Possible values are 'web', 'ios', 'java', 'phone', 'MobileCenter', 'other', 'store'.

Type: `string`

Default: `"web"`

### <a name="input_daily_data_cap_in_gb"></a> [daily\_data\_cap\_in\_gb](#input\_daily\_data\_cap\_in\_gb)

Description: (Optional) The daily data cap in GB. 0 means unlimited.

Type: `number`

Default: `100`

### <a name="input_daily_data_cap_notifications_disabled"></a> [daily\_data\_cap\_notifications\_disabled](#input\_daily\_data\_cap\_notifications\_disabled)

Description: (Optional) Disables the daily data cap notifications.

Type: `bool`

Default: `false`

### <a name="input_disable_ip_masking"></a> [disable\_ip\_masking](#input\_disable\_ip\_masking)

Description: (Optional) Disables IP masking. Defaults to false. For more information see <https://aka.ms/avm/ipmasking>.

Type: `bool`

Default: `false`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_force_customer_storage_for_profiler"></a> [force\_customer\_storage\_for\_profiler](#input\_force\_customer\_storage\_for\_profiler)

Description: (Optional) Forces customer storage for profiler. Defaults to false.

Type: `bool`

Default: `false`

### <a name="input_internet_ingestion_enabled"></a> [internet\_ingestion\_enabled](#input\_internet\_ingestion\_enabled)

Description: (Optional) Enables internet ingestion. Defaults to true.

Type: `bool`

Default: `true`

### <a name="input_internet_query_enabled"></a> [internet\_query\_enabled](#input\_internet\_query\_enabled)

Description: (Optional) Enables internet query. Defaults to true.

Type: `bool`

Default: `true`

### <a name="input_linked_storage_account"></a> [linked\_storage\_account](#input\_linked\_storage\_account)

Description:   Linked storage account configuration for the Application Insights profiler.

  - `resource_id` - The resource ID of the storage account.

Type:

```hcl
map(object({
    resource_id = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_local_authentication_disabled"></a> [local\_authentication\_disabled](#input\_local\_authentication\_disabled)

Description: (Optional) Disables local authentication. Defaults to false.

Type: `bool`

Default: `false`

### <a name="input_lock"></a> [lock](#input\_lock)

Description:   Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:   Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_monitor_private_link_scope"></a> [monitor\_private\_link\_scope](#input\_monitor\_private\_link\_scope)

Description:   Monitor private link scope to connect the Application Insights resource to.

  - `resource_id` - The resource ID of the monitor private link scope.
  - `name` - The name of the scoped resource. Defaults to the Application Insights resource name.
  - `kind` - The kind of the scoped resource. Defaults to `Resource`. Possible values are `Resource` or `Metrics`.
  - `subscription_location` - The location of the subscription. This is required for kind `Metrics`.

Type:

```hcl
map(object({
    resource_id           = optional(string, null)
    name                  = optional(string, null)
    kind                  = optional(string, "Resource")
    subscription_location = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_retention_in_days"></a> [retention\_in\_days](#input\_retention\_in\_days)

Description: (Optional) The retention period in days. 0 means unlimited.

Type: `number`

Default: `90`

### <a name="input_sampling_percentage"></a> [sampling\_percentage](#input\_sampling\_percentage)

Description: (Optional) The sampling percentage. 100 means all.

Type: `number`

Default: `100`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_app_id"></a> [app\_id](#output\_app\_id)

Description: App ID of the Application Insights

### <a name="output_connection_string"></a> [connection\_string](#output\_connection\_string)

Description: Connection String of the Application Insights

### <a name="output_instrumentation_key"></a> [instrumentation\_key](#output\_instrumentation\_key)

Description: Instrumentation Key of the Application Insights

### <a name="output_name"></a> [name](#output\_name)

Description: Name of the Application Insights

### <a name="output_resource"></a> [resource](#output\_resource)

Description: This is the full output for the resource.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ID of the Application Insights

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
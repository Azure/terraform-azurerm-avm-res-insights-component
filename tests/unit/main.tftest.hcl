mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/components/appi-test"
      output = {
        properties = {
          AppId              = "11111111-1111-1111-1111-111111111111"
          ConnectionString   = "InstrumentationKey=22222222-2222-2222-2222-222222222222;ApplicationId=11111111-1111-1111-1111-111111111111"
          InstrumentationKey = "22222222-2222-2222-2222-222222222222"
        }
      }
    }
  }

  mock_data "azapi_resource_list" {
    defaults = {
      output = {
        results = [
          {
            id        = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/43d0d8ad-25c7-4714-9337-8ba259a9fe05"
            role_name = "Monitoring Reader"
          }
        ]
      }
    }
  }
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "random" {}

mock_provider "time" {}

variables {
  enable_telemetry = false
  location         = "westus2"
  name             = "appi-test"
  parent_id        = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  workspace_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-test"
}

run "defaults" {
  command = apply

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Insights/components@2020-02-02"
    error_message = "The component should use the default resource type."
  }
  assert {
    condition     = azapi_resource.this.parent_id == var.parent_id && azapi_resource.this.name == "appi-test" && azapi_resource.this.location == "westus2"
    error_message = "The component should be deployed into the parent resource group."
  }
  assert {
    condition     = azapi_resource.this.body.kind == "web" && azapi_resource.this.body.properties.Application_Type == "web"
    error_message = "The application type should set both the kind and Application_Type."
  }
  assert {
    condition = (
      azapi_resource.this.body.properties.DisableIpMasking == false &&
      azapi_resource.this.body.properties.DisableLocalAuth == false &&
      azapi_resource.this.body.properties.ForceCustomerStorageForProfiler == false &&
      azapi_resource.this.body.properties.RetentionInDays == 90 &&
      azapi_resource.this.body.properties.SamplingPercentage == 100 &&
      azapi_resource.this.body.properties.WorkspaceResourceId == var.workspace_id &&
      azapi_resource.this.body.properties.publicNetworkAccessForIngestion == "Enabled" &&
      azapi_resource.this.body.properties.publicNetworkAccessForQuery == "Enabled"
    )
    error_message = "The component properties should match the AzureRM provider defaults."
  }
  assert {
    condition     = azapi_resource.this.replace_triggers_refs == tolist(["properties.Application_Type"])
    error_message = "A change to the application type should replace the component."
  }
  assert {
    condition     = azapi_update_resource.pricing_plan.parent_id == azapi_resource.this.id && azapi_update_resource.pricing_plan.name == "current" && azapi_update_resource.pricing_plan.type == "microsoft.insights/components/pricingPlans@2017-10-01"
    error_message = "The daily data cap should be set on the component's current pricing plan."
  }
  assert {
    condition     = azapi_update_resource.pricing_plan.body.properties.cap == 100 && azapi_update_resource.pricing_plan.body.properties.stopSendNotificationWhenHitCap == false
    error_message = "The daily data cap should default to 100 GB with notifications enabled."
  }
  assert {
    condition     = length(azapi_resource.lock) == 0 && length(time_sleep.lock_removal) == 0
    error_message = "No lock or lock removal pause should be created without a lock."
  }
  assert {
    condition     = output.resource_id == azapi_resource.this.id && output.name == "appi-test"
    error_message = "The resource ID and name outputs should come from the component."
  }
  assert {
    condition     = output.app_id == "11111111-1111-1111-1111-111111111111" && output.instrumentation_key == "22222222-2222-2222-2222-222222222222" && startswith(output.connection_string, "InstrumentationKey=22222222")
    error_message = "The assigned value outputs should come from the component."
  }
  assert {
    condition     = output.resource.resource_group_name == "rg-test" && output.resource.location == "westus2" && output.resource.retention_in_days == 90 && output.resource.sampling_percentage == 100
    error_message = "The resource output should keep the AzureRM attribute names."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "null_inputs_use_the_azurerm_defaults" {
  command = plan

  variables {
    application_type                      = null
    daily_data_cap_in_gb                  = null
    daily_data_cap_notifications_disabled = null
    disable_ip_masking                    = null
    force_customer_storage_for_profiler   = null
    internet_ingestion_enabled            = null
    internet_query_enabled                = null
    local_authentication_disabled         = null
    retention_in_days                     = null
    sampling_percentage                   = null
  }

  assert {
    condition = (
      azapi_resource.this.body.kind == "web" &&
      azapi_resource.this.body.properties.DisableIpMasking == false &&
      azapi_resource.this.body.properties.DisableLocalAuth == false &&
      azapi_resource.this.body.properties.ForceCustomerStorageForProfiler == false &&
      azapi_resource.this.body.properties.RetentionInDays == 90 &&
      azapi_resource.this.body.properties.SamplingPercentage == 100 &&
      azapi_resource.this.body.properties.publicNetworkAccessForIngestion == "Enabled" &&
      azapi_resource.this.body.properties.publicNetworkAccessForQuery == "Enabled"
    )
    error_message = "Null inputs should use the defaults that the AzureRM provider applied."
  }
  assert {
    condition     = azapi_update_resource.pricing_plan.body.properties.cap == 100 && azapi_update_resource.pricing_plan.body.properties.stopSendNotificationWhenHitCap == false
    error_message = "Null daily data cap inputs should use the defaults that the AzureRM provider applied."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "settings_are_mapped" {
  command = plan

  variables {
    application_type                      = "Node.JS"
    daily_data_cap_in_gb                  = 0.5
    daily_data_cap_notifications_disabled = true
    disable_ip_masking                    = true
    force_customer_storage_for_profiler   = true
    internet_ingestion_enabled            = false
    internet_query_enabled                = false
    local_authentication_disabled         = true
    retention_in_days                     = 30
    sampling_percentage                   = 12.5
    tags                                  = { environment = "test" }
  }

  assert {
    condition = (
      azapi_resource.this.body.kind == "Node.JS" &&
      azapi_resource.this.body.properties.Application_Type == "Node.JS" &&
      azapi_resource.this.body.properties.DisableIpMasking == true &&
      azapi_resource.this.body.properties.DisableLocalAuth == true &&
      azapi_resource.this.body.properties.ForceCustomerStorageForProfiler == true &&
      azapi_resource.this.body.properties.RetentionInDays == 30 &&
      azapi_resource.this.body.properties.SamplingPercentage == 12.5 &&
      azapi_resource.this.body.properties.publicNetworkAccessForIngestion == "Disabled" &&
      azapi_resource.this.body.properties.publicNetworkAccessForQuery == "Disabled"
    )
    error_message = "The component properties should follow the inputs."
  }
  assert {
    condition     = azapi_resource.this.tags == tomap({ environment = "test" })
    error_message = "The tags should be set on the component."
  }
  assert {
    condition     = azapi_update_resource.pricing_plan.body.properties.cap == 0.5 && azapi_update_resource.pricing_plan.body.properties.stopSendNotificationWhenHitCap == true
    error_message = "The daily data cap settings should follow the inputs."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "ignored_pricing_plan_properties_are_not_sent" {
  command = plan

  variables {
    ignore_body_changes = {
      insights_components_pricing_plans = ["properties.cap"]
    }
  }

  assert {
    condition     = keys(azapi_update_resource.pricing_plan.body.properties) == ["stopSendNotificationWhenHitCap"]
    error_message = "An ignored pricing plan property should be left out of the update."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "ignoring_all_pricing_plan_properties" {
  command = plan

  variables {
    ignore_body_changes = {
      insights_components_pricing_plans = ["properties"]
    }
  }

  assert {
    condition     = length(azapi_update_resource.pricing_plan.body.properties) == 0
    error_message = "Ignoring `properties` should leave every pricing plan property out of the update."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "resource_types_can_be_overridden" {
  command = plan

  variables {
    resource_types = {
      insights_components_pricing_plans = "Microsoft.Insights/components/pricingPlans@2017-10-01"
    }
  }

  assert {
    condition     = azapi_resource.this.type == "Microsoft.Insights/components@2020-02-02" && azapi_update_resource.pricing_plan.type == "Microsoft.Insights/components/pricingPlans@2017-10-01"
    error_message = "The resource types should follow the override."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "lock_without_a_name" {
  command = apply

  variables {
    lock = {
      kind = "CanNotDelete"
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-appi-test" && azapi_resource.lock[0].type == "Microsoft.Authorization/locks@2020-05-01"
    error_message = "An unnamed lock should be named after the component."
  }
  assert {
    condition     = keys(azapi_resource.lock[0].body.properties) == ["level"] && azapi_resource.lock[0].body.properties.level == "CanNotDelete"
    error_message = "A lock without notes should not send notes."
  }
  assert {
    condition     = azapi_resource.lock[0].parent_id == azapi_resource.this.id
    error_message = "The lock should be scoped to the component."
  }
  assert {
    condition     = time_sleep.lock_removal[0].destroy_duration == "30s"
    error_message = "Destroying the lock should be followed by a pause."
  }
  assert {
    condition     = time_sleep.lock_removal[0].triggers == tomap({ component_id = azapi_resource.this.id })
    error_message = "Replacing the component should replace the pause as well."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "lock_with_a_name_and_notes" {
  command = plan

  variables {
    lock = {
      kind  = "ReadOnly"
      name  = "lock-custom"
      notes = "Managed by Terraform."
    }
  }

  assert {
    condition     = azapi_resource.lock[0].name == "lock-custom"
    error_message = "A named lock should keep its name."
  }
  assert {
    condition     = azapi_resource.lock[0].body.properties.level == "ReadOnly" && azapi_resource.lock[0].body.properties.notes == "Managed by Terraform."
    error_message = "The lock should send its level and notes."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "role_assignments" {
  command = apply

  variables {
    role_assignments = {
      reader = {
        principal_id               = "AAAAAAAA-0000-0000-0000-000000000000"
        role_definition_id_or_name = "Monitoring Reader"
      }
    }
  }

  assert {
    condition     = azapi_resource.role_assignment["reader"].type == "Microsoft.Authorization/roleAssignments@2022-04-01" && azapi_resource.role_assignment["reader"].parent_id == azapi_resource.this.id
    error_message = "The role assignment should be created on the component."
  }
  assert {
    condition     = azapi_resource.role_assignment["reader"].body.properties.roleDefinitionId == "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    error_message = "The role definition name should be resolved to its ID."
  }
  assert {
    condition = (
      azapi_resource.role_assignment["reader"].replace_triggers_external_values.name == null &&
      azapi_resource.role_assignment["reader"].replace_triggers_external_values.principal_id == "aaaaaaaa-0000-0000-0000-000000000000" &&
      azapi_resource.role_assignment["reader"].replace_triggers_external_values.role_definition_id_or_name == "monitoring reader"
    )
    error_message = "A change of principal or role should replace the role assignment."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "children_are_created_on_the_component" {
  command = plan

  variables {
    diagnostic_settings = {
      law = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/law-diag"
      }
    }
    linked_storage_account = {
      profiler = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/stprofiler"
      }
    }
    monitor_private_link_scope = {
      ampls = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/privateLinkScopes/ampls-test"
      }
    }
  }

  assert {
    condition     = azapi_resource.diagnostic_settings["law"].type == "Microsoft.Insights/diagnosticSettings@2021-05-01-preview" && azapi_resource.diagnostic_settings["law"].name == "diag-appi-test"
    error_message = "The diagnostic setting should use the default type and name."
  }
  assert {
    condition     = azapi_resource.diagnostic_settings["law"].body.properties.logs[0].categoryGroup == "allLogs" && azapi_resource.diagnostic_settings["law"].body.properties.metrics[0].category == "AllMetrics"
    error_message = "A diagnostic setting without logs or metrics should send all logs and metrics."
  }
  assert {
    condition     = azapi_resource.linked_storage_account["profiler"].name == "serviceprofiler" && azapi_resource.linked_storage_account["profiler"].type == "microsoft.insights/components/linkedStorageAccounts@2020-03-01-preview"
    error_message = "The linked storage account should keep its name and type."
  }
  assert {
    condition     = azapi_resource.monitor_private_link_scope["ampls"].name == "appi-test" && azapi_resource.monitor_private_link_scope["ampls"].parent_id == var.monitor_private_link_scope.ampls.resource_id && azapi_resource.monitor_private_link_scope["ampls"].body.properties.kind == "Resource"
    error_message = "The private link scope connection should be named after the component."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "parent_id_is_normalised" {
  command = plan

  variables {
    parent_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/Rg-Test"
  }

  assert {
    condition     = azapi_resource.this.parent_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/Rg-Test"
    error_message = "The resource group segment of the parent ID should be normalised, and the name kept as given."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "invalid_inputs_are_rejected" {
  command = plan

  variables {
    daily_data_cap_in_gb = -1
    parent_id            = "/subscriptions/00000000-0000-0000-0000-000000000000"
    retention_in_days    = 45
    sampling_percentage  = 101
    workspace_id         = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Storage/storageAccounts/stexample"
    diagnostic_settings = {
      law = {
        workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
      }
    }
    linked_storage_account = {
      profiler = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
      }
    }
    monitor_private_link_scope = {
      ampls = {
        resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
      }
    }
  }

  expect_failures = [
    var.daily_data_cap_in_gb,
    var.diagnostic_settings,
    var.linked_storage_account,
    var.monitor_private_link_scope,
    var.parent_id,
    var.retention_in_days,
    var.sampling_percentage,
    var.workspace_id,
  ]
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

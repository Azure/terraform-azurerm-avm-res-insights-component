resource "azapi_resource" "this" {
  location  = var.location
  name      = var.name
  parent_id = local.parent_id
  type      = var.resource_types.insights_components
  body = {
    kind = var.application_type
    properties = {
      Application_Type                = var.application_type
      DisableIpMasking                = var.disable_ip_masking
      DisableLocalAuth                = var.local_authentication_disabled
      ForceCustomerStorageForProfiler = var.force_customer_storage_for_profiler
      RetentionInDays                 = var.retention_in_days
      SamplingPercentage              = var.sampling_percentage
      WorkspaceResourceId             = var.workspace_id
      publicNetworkAccessForIngestion = var.internet_ingestion_enabled ? "Enabled" : "Disabled"
      publicNetworkAccessForQuery     = var.internet_query_enabled ? "Enabled" : "Disabled"
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.insights_components) > 0 ? var.ignore_body_changes.insights_components : null
  # Azure keeps the original application type when an existing component is updated, so a change
  # replaces the component, as it did with the AzureRM provider.
  replace_triggers_refs = [
    "properties.Application_Type",
  ]
  response_export_values = [
    "properties.AppId",
    "properties.ConnectionString",
    "properties.InstrumentationKey",
  ]
  retry = var.retry
  tags  = var.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

moved {
  from = azurerm_application_insights.this
  to   = azapi_resource.this
}

# The AzAPI provider plans the component's output as unknown whenever the component has any pending
# change, which would leave these outputs unknown in that plan and change anything a consumer builds
# from them, such as app settings. Azure assigns these values when it creates the component, so they
# are copied once and only copied again when the component is replaced.
resource "terraform_data" "application_insights_assigned_values" {
  input = {
    app_id              = azapi_resource.this.output.properties.AppId
    connection_string   = azapi_resource.this.output.properties.ConnectionString
    instrumentation_key = azapi_resource.this.output.properties.InstrumentationKey
  }
  # The component's ID stays known through in-place updates and is only unknown when the component
  # is replaced.
  triggers_replace = azapi_resource.this.id

  lifecycle {
    ignore_changes = [input]
  }
}

# The daily data cap is not part of the component. The pricing plan always exists, so it is updated
# rather than created, and destroying this resource leaves it unchanged.
resource "azapi_update_resource" "pricing_plan" {
  name      = "current"
  parent_id = azapi_resource.this.id
  type      = var.resource_types.insights_components_pricing_plans
  body = {
    properties = local.pricing_plan_properties
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azapi_resource" "monitor_private_link_scope" {
  for_each = var.monitor_private_link_scope

  name      = each.value.name != null ? each.value.name : azapi_resource.this.name
  parent_id = each.value.resource_id
  type      = var.resource_types.insights_private_link_scopes_scoped_resources
  body = {
    properties = {
      kind                 = each.value.kind
      linkedResourceId     = azapi_resource.this.id
      subscriptionLocation = each.value.subscription_location
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.insights_private_link_scopes_scoped_resources) > 0 ? var.ignore_body_changes.insights_private_link_scopes_scoped_resources : null
  ignore_casing          = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Azure does not delete a component that is still linked to a private link scope, so the
    # connection is replaced, and deleted first, when the component is replaced.
    replace_triggered_by = [azapi_resource.this.id]
  }
  # The connection is stored with the component, like the pricing plan and the linked storage account,
  # and Azure rejects concurrent changes to it.
  depends_on = [
    azapi_update_resource.pricing_plan,
    azapi_resource.linked_storage_account,
  ]
}

resource "azapi_resource" "linked_storage_account" {
  for_each = var.linked_storage_account

  name      = "serviceprofiler"
  parent_id = azapi_resource.this.id
  type      = var.resource_types.insights_components_linked_storage_accounts
  body = {
    properties = {
      linkedStorageAccount = each.value.resource_id
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.insights_components_linked_storage_accounts) > 0 ? var.ignore_body_changes.insights_components_linked_storage_accounts : null
  ignore_casing          = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # The linked storage account and the pricing plan are both stored with the component, and Azure
  # rejects concurrent changes to it with a conflict.
  depends_on = [azapi_update_resource.pricing_plan]
}

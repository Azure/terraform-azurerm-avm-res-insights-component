# AVM Interfaces module for locks, role assignments, and diagnostic settings
module "avm_interfaces" {
  source  = "Azure/avm-utl-interfaces/azure"
  version = "0.9.0"

  location                                  = var.location
  diagnostic_settings_v2                    = local.diagnostic_settings_with_names
  enable_telemetry                          = var.enable_telemetry
  lock                                      = var.lock
  role_assignment_definition_lookup_enabled = true
  role_assignment_definition_scope          = "/subscriptions/${local.subscription_id}"
  role_assignments                          = var.role_assignments
}

moved {
  from = azurerm_management_lock.this
  to   = azapi_resource.lock
}

moved {
  from = azurerm_role_assignment.this
  to   = azapi_resource.role_assignment
}

# Lock
resource "azapi_resource" "lock" {
  count = var.lock != null ? 1 : 0

  name      = coalesce(module.avm_interfaces.lock_azapi.name, "lock-${var.name}")
  parent_id = azapi_resource.this.id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      for property, value in module.avm_interfaces.lock_azapi.body.properties : property => value if value != null
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts != null ? { this = var.timeouts } : {}

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  # Create the lock last and remove it first. A ReadOnly lock blocks changes to the resources under it.
  depends_on = [time_sleep.lock_removal]
}

# Azure keeps enforcing a deleted lock for a few seconds, and the AzAPI provider does not wait for it to
# be gone. This pause is destroyed after the lock and before the component and the resources under it,
# so they are not deleted while the lock still applies.
resource "time_sleep" "lock_removal" {
  count = var.lock != null ? 1 : 0

  destroy_duration = "30s"
  # Replacing the component replaces its lock, so the pause is replaced with them.
  triggers = {
    component_id = azapi_resource.this.id
  }

  depends_on = [
    azapi_resource.this,
    azapi_resource.diagnostic_settings,
    azapi_resource.linked_storage_account,
    azapi_resource.monitor_private_link_scope,
    azapi_resource.role_assignment,
    azapi_update_resource.pricing_plan,
  ]
}

# Role Assignments
resource "azapi_resource" "role_assignment" {
  for_each = module.avm_interfaces.role_assignments_azapi

  name                = each.value.name
  parent_id           = azapi_resource.this.id
  type                = var.resource_types.authorization_role_assignments
  body                = each.value.body
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  # Azure does not allow the principal or the role of an existing assignment to change. The inputs are
  # compared rather than body paths, because Azure normalises role definition IDs. While a prior value
  # is null, as it is after upgrading, nothing is replaced.
  replace_triggers_external_values = {
    name                       = var.role_assignments[each.key].name
    principal_id               = lower(var.role_assignments[each.key].principal_id)
    role_definition_id_or_name = lower(var.role_assignments[each.key].role_definition_id_or_name)
  }
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts != null ? { this = var.timeouts } : {}

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  lifecycle {
    # Assignments moved from the AzureRM provider keep the name it generated, while the interfaces
    # module generates a new one. Replacing them would fail under a CanNotDelete lock. A change to an
    # explicit name still replaces the assignment through replace_triggers_external_values. Azure sets
    # the principal type when it is not given, and it cannot change on an existing assignment.
    ignore_changes = [name, body.properties.principalType]
  }
}

# Diagnostic Settings
resource "azapi_resource" "diagnostic_settings" {
  for_each = module.avm_interfaces.diagnostic_settings_azapi_v2

  name                   = each.value.name
  parent_id              = azapi_resource.this.id
  type                   = var.resource_types.insights_diagnostic_settings
  body                   = each.value.body
  ignore_body_changes    = length(var.ignore_body_changes.insights_diagnostic_settings) > 0 ? var.ignore_body_changes.insights_diagnostic_settings : null
  ignore_casing          = true
  ignore_null_property   = true
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts != null ? { this = var.timeouts } : {}

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

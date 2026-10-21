locals {
  diagnostic_settings_with_names = {
    for key, diagnostic_setting in var.diagnostic_settings : key => merge(diagnostic_setting, {
      name = coalesce(diagnostic_setting.name, "diag-${var.name}")
      logs = length(try(diagnostic_setting.logs, [])) == 0 && length(try(diagnostic_setting.metrics, [])) == 0 ? [
        {
          category       = null
          category_group = "allLogs"
          enabled        = true
          retention_policy = {
            days    = 0
            enabled = false
          }
        }
      ] : diagnostic_setting.logs
      metrics = length(try(diagnostic_setting.logs, [])) == 0 && length(try(diagnostic_setting.metrics, [])) == 0 ? [
        {
          category = "AllMetrics"
          enabled  = true
          retention_policy = {
            days    = 0
            enabled = false
          }
        }
      ] : diagnostic_setting.metrics
    })
  }
  # azapi_update_resource has no ignore_body_changes argument, so ignored properties are left out of the
  # update instead. The update reads and writes back every property it does not set.
  pricing_plan_properties = {
    for property, value in {
      cap                            = var.daily_data_cap_in_gb
      stopSendNotificationWhenHitCap = var.daily_data_cap_notifications_disabled
    } : property => value
    if !contains(var.ignore_body_changes.insights_components_pricing_plans, "properties") && !contains(var.ignore_body_changes.insights_components_pricing_plans, "properties.${property}")
  }
  # The AzAPI provider replaces the component when the text of its parent ID changes, even only in case.
  # The ID is rebuilt with the standard resourceGroups segment, which IDs Azure returns sometimes lower-case.
  parent_id           = "/subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group_name}"
  resource_group_name = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).resource_group_name
  subscription_id     = provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.parent_id).subscription_id
}

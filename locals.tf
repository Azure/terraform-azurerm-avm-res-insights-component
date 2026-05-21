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
}

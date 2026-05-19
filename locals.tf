locals {
  diagnostic_settings_with_names = {
    for key, diagnostic_setting in var.diagnostic_settings : key => merge(diagnostic_setting, {
      name = coalesce(diagnostic_setting.name, "diag-${var.name}")
    })
  }
}

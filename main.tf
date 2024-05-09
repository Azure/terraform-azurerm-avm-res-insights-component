

resource "azurerm_application_insights" "this" {
  application_type                      = var.application_type
  location                              = var.location
  name                                  = "${var.app_insights_prefix}-${var.name}"
  resource_group_name                   = var.resource_group_name
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
  disable_ip_masking                    = var.disable_ip_masking
  retention_in_days                     = var.retention_in_days
  sampling_percentage                   = var.sampling_percentage
  tags                                  = var.tags
  workspace_id                          = var.workspace_id
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.name}")
  scope      = azurerm_application_insights.this.id
}


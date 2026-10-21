# terraform-azurerm-avm-res-insights-component

This module deploys a workspace-based Application Insights component with the AzAPI provider. It does not use the AzureRM provider.

## Upgrading from 0.4.x or earlier

The component and its lock and role assignments are moved to AzAPI resources in the state, so nothing is recreated.

1. Replace `resource_group_name` with `parent_id`, the resource ID of the resource group. Keep the case of the resource group name as it was, because a change in case replaces the component.
1. A `ReadOnly` lock blocks the upgrade, because the component is updated. Change it to `CanNotDelete`, or remove it, until the upgrade is applied.
1. Run `terraform init -upgrade`, then `terraform plan`. The plan must not destroy or replace anything. It updates the component and the resources moved with it in place, and adds:
   - `azapi_update_resource.pricing_plan`, which applies the same daily data cap settings;
   - `terraform_data.application_insights_assigned_values`, which only exists in the state and keeps `app_id`, `connection_string` and `instrumentation_key` stable. In this plan only, those outputs are known after apply. Their values do not change;
   - `time_sleep.lock_removal`, when a lock is set;
   - from 0.3.x, a `random_uuid` for each role assignment, which only exists in the state. The assignments keep their names;
   - the AVM telemetry resources, when telemetry is enabled. The previous telemetry resources are removed from the state without being destroyed.

Other changes:

- A lock without a name is named `lock-<name>` again, as in 0.3.x.
- `instrumentation_key` is now marked as sensitive, as the AzureRM provider already treated it.
- The `resource` output is deprecated. It keeps the AzureRM attribute names that map to this module's inputs, but no longer includes `connection_string` or `instrumentation_key`.
- Azure creates a `Failure Anomalies - <name>` smart detector alert rule for each new component. The AzureRM provider's `application_insights.disable_generated_rule` feature disabled it and deleted it with the component. Without it, the rule is kept, as it was by default.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
> 
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
> 
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

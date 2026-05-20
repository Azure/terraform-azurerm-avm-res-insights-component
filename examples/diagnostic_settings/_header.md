# Diagnostic Settings

This deploys the module with diagnostic settings enabled.

If both `logs` and `metrics` are omitted or left empty, the module defaults to enabling `allLogs` and `AllMetrics`.

If only one side is provided, the other side remains unset. For example, supplying `logs` without `metrics` does not automatically enable metrics, and supplying `metrics` without `logs` does not automatically enable logs.

If you choose individual categories instead of the defaults, define the full supported set with explicit `true` and `false` values. The Azure API normalizes diagnostic settings by category, so partial category lists can drift on later plans.

At this resource scope, metrics currently support only `AllMetrics`.

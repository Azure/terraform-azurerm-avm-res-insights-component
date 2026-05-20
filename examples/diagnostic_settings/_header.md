# Diagnostic Settings

This deploys the module with diagnostic settings enabled.

If both `logs` and `metrics` are omitted or left empty, the module defaults to enabling `allLogs` and `AllMetrics`.

If you choose individual categories instead of the defaults, define the full supported set with explicit `true` and `false` values. The Azure API normalizes diagnostic settings by category, so partial category lists can drift on later plans.

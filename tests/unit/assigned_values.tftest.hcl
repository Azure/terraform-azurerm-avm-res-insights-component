mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/components/appi-test"
      output = {
        properties = {
          AppId              = "11111111-1111-1111-1111-111111111111"
          ConnectionString   = "InstrumentationKey=22222222-2222-2222-2222-222222222222"
          InstrumentationKey = "22222222-2222-2222-2222-222222222222"
        }
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

run "copies_the_assigned_values" {
  command = apply

  assert {
    condition     = output.app_id == "11111111-1111-1111-1111-111111111111" && output.instrumentation_key == "22222222-2222-2222-2222-222222222222" && output.connection_string == "InstrumentationKey=22222222-2222-2222-2222-222222222222"
    error_message = "The outputs should hold the values Azure assigned to the component."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "keeps_the_values_through_an_update" {
  command = apply

  variables {
    tags = {
      environment = "test"
    }
  }

  override_resource {
    target = azapi_resource.this
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/components/appi-test"
      output = {
        properties = {
          AppId              = "33333333-3333-3333-3333-333333333333"
          ConnectionString   = "InstrumentationKey=44444444-4444-4444-4444-444444444444"
          InstrumentationKey = "44444444-4444-4444-4444-444444444444"
        }
      }
    }
  }

  assert {
    condition     = output.app_id == "11111111-1111-1111-1111-111111111111" && output.instrumentation_key == "22222222-2222-2222-2222-222222222222" && output.connection_string == "InstrumentationKey=22222222-2222-2222-2222-222222222222"
    error_message = "An in-place update of the component should not change the copied values."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

run "copies_the_values_again_when_the_component_is_replaced" {
  command = apply

  variables {
    tags = {
      environment = "test"
    }
  }

  plan_options {
    replace = [azapi_resource.this]
  }

  override_resource {
    target = azapi_resource.this
    values = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Insights/components/appi-test"
      output = {
        properties = {
          AppId              = "33333333-3333-3333-3333-333333333333"
          ConnectionString   = "InstrumentationKey=44444444-4444-4444-4444-444444444444"
          InstrumentationKey = "44444444-4444-4444-4444-444444444444"
        }
      }
    }
  }

  assert {
    condition     = output.app_id == "33333333-3333-3333-3333-333333333333" && output.instrumentation_key == "44444444-4444-4444-4444-444444444444" && output.connection_string == "InstrumentationKey=44444444-4444-4444-4444-444444444444"
    error_message = "Replacing the component should copy the values Azure assigned to the new one."
  }
  providers = {
    azapi  = azapi
    random = random
    time   = time
  }
}

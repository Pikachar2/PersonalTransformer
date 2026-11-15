data:extend
{
  -- Startup: General
  {
    type = "bool-setting",
    name = "personal-transformer2-allow-non-armor",
    setting_type = "startup",
    default_value = false,
    order = "a1"
  },

  -- Startup: MK1
  {
    type = "double-setting",
    name = "personal-transformer-mk1-flow-limit",
    setting_type = "startup",
    minimum_value = 0,
    default_value = 200,
    order = "b1"
  },
  {
    type = "double-setting",
    name = "personal-transformer-mk1-output-limit",
    setting_type = "startup",
    minimum_value = 0,
    default_value = 200,
    order = "b2"
  },
  {
    type = "double-setting",
    name = "personal-transformer-mk1-buffer-capacity",
    setting_type = "startup",
    minimum_value = 0,
    default_value = 20,
    order = "b3"
  },

  -- Startup: MK2
  {
    type = "double-setting",
    name = "personal-transformer-mk2-flow-limit",
    setting_type = "startup",
    minimum_value = 0,
    default_value = 1000,
    order = "c1"
  },
  {
    type = "double-setting",
    name = "personal-transformer-mk2-output-limit",
    setting_type = "startup",
    minimum_value = 0,
    default_value = 1000,
    order = "c2"
  },
  {
    type = "double-setting",
    name = "personal-transformer-mk2-buffer-capacity",
    setting_type = "startup",
    minimum_value = 0,
    default_value = 100,
    order = "c3"
  },

  -- Startup: MK3
  {
    type = "double-setting",
    name = "personal-transformer-mk3-flow-limit",
    setting_type = "startup",
    minimum_value = 0,
    default_value = 4000,
    order = "d1"
  },
  {
    type = "double-setting",
    name = "personal-transformer-mk3-output-limit",
    setting_type = "startup",
    minimum_value = 0,
    default_value = 4000,
    order = "d2"
  },
  {
    type = "double-setting",
    name = "personal-transformer-mk3-buffer-capacity",
    setting_type = "startup",
    minimum_value = 0,
    default_value = 400,
    order = "d3"
  },

  -- Runtime Global (Map)
  {
    type = "int-setting",
    name = "personal-transformer2-tick-delay",
    setting_type = "runtime-global",
    minimum_value = 1,
    maximum_value = 60,
    default_value = 1,
    order = "e1"
  },

  -- Runtime Per-User
  {
    type = "bool-setting",
    name = "personal-transformer2-default-vehicle-in",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "f1"
  },
  {
    type = "bool-setting",
    name = "personal-transformer2-default-vehicle-out",
    setting_type = "runtime-per-user",
    default_value = false,
    order = "f2"
  }
}

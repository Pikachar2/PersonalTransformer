data:extend
{
  {
    type = "bool-setting",
    name = "personal-transformer2-allow-non-armor",
    setting_type = "startup",
    default_value = false,
    per_user = false,
    order = "a1"
  },
  {
    type = "int-setting",
    name = "personal-transformer2-tick-delay",
    setting_type = "runtime-global",
	minimum_value = 1,
	maximum_value = 60,
    default_value = 1,
    per_user = false,
    order = "a2"
  }
}
data:extend({
	{
		type = "equipment-category",
		name = "armor-transformer"
	}
})

local TIER_CONFIGS = {
	{
		equip = "personal-transformer-equipment",
		input = "personal-transformer-input-entity",
		output = "personal-transformer-output-entity",
		limit = settings.startup["personal-transformer-mk1-flow-limit"].value
	},
	{
		equip = "personal-transformer-mk2-equipment",
		input = "personal-transformer-mk2-input-entity",
		output = "personal-transformer-mk2-output-entity",
		limit = settings.startup["personal-transformer-mk2-flow-limit"].value
	},
	{
		equip = "personal-transformer-mk3-equipment",
		input = "personal-transformer-mk3-input-entity",
		output = "personal-transformer-mk3-output-entity",
		limit = settings.startup["personal-transformer-mk3-flow-limit"].value
	}
}

for _, tier in ipairs(TIER_CONFIGS) do
	local equip = data.raw["battery-equipment"][tier.equip]
	equip.energy_source.input_flow_limit = tier.limit .. "kW"
	equip.energy_source.output_flow_limit = tier.limit .. "kW"
	equip.energy_source.buffer_capacity = (tier.limit / 10) .. "kJ"

	local input_ent = data.raw["electric-energy-interface"][tier.input]
	input_ent.energy_source.input_flow_limit = "100GW"
	input_ent.energy_source.output_flow_limit = "0W"
	input_ent.energy_source.buffer_capacity = "100GJ"

	local output_ent = data.raw["electric-energy-interface"][tier.output]
	output_ent.energy_source.input_flow_limit = "0W"
	output_ent.energy_source.output_flow_limit = "100GW"
	output_ent.energy_source.buffer_capacity = "100GJ"
end

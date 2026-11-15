local all_resistances = {
	{ type = 'physical', percent = 100 },
	{ type = 'impact', percent = 100 },
	{ type = 'poison', percent = 100 },
	{ type = 'explosion', percent = 100 },
	{ type = 'fire', percent = 100 },
	{ type = 'laser', percent = 100 },
	{ type = 'acid', percent = 100 },
	{ type = 'electric', percent = 100 }
}

local function make_proxy_entity(name, usage_priority, input_limit, output_limit, buffer_cap)
	return {
		type = 'electric-energy-interface',
		name = name,
		icon = '__base__/graphics/icons/power-armor.png',
		icon_size = 32,
		flags = { 'placeable-off-grid', 'not-on-map' },
		minable = nil,
		max_health = 500,
		resistances = all_resistances,
		hidden = true,
		hidden_in_factoriopedia = true,
		collision_box = {{ -0.2, -0.2 }, { 0.2, 0.2 }},
		selection_box = {{ -0.01, -0.01 }, { 0.01, 0.01 }},
		collision_mask = { layers = {} },
		alert_icon_scale = 0,
		energy_source = {
			type = 'electric',
			buffer_capacity = buffer_cap,
			usage_priority = usage_priority,
			input_flow_limit = input_limit,
			output_flow_limit = output_limit
		},
		picture = {
			layers = {
				{
					filename = '__PersonalTransformer2__/graphics/empty.png',
					priority = "high",
					frames = 1,
					width = 32,
					height = 32
				}
			}
		}
	}
end

data:extend{
	make_proxy_entity('personal-transformer-input-entity', 'secondary-input', '200kW', '0kW', '20kJ'),
	make_proxy_entity('personal-transformer-output-entity', 'tertiary', '0kW', '200kW', '20kJ'),
	make_proxy_entity('personal-transformer-mk2-input-entity', 'secondary-input', '1MW', '0kW', '100kJ'),
	make_proxy_entity('personal-transformer-mk2-output-entity', 'tertiary', '0kW', '1MW', '100kJ'),
	make_proxy_entity('personal-transformer-mk3-input-entity', 'secondary-input', '4MW', '0kW', '400kJ'),
	make_proxy_entity('personal-transformer-mk3-output-entity', 'tertiary', '0kW', '4MW', '400kJ')
}

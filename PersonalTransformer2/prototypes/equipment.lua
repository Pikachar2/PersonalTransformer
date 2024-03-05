--data:extend{
local transformer_eq = {
	["transformer-1"] = {
		type = 'battery-equipment',
		name = 'personal-transformer-equipment',
		sprite =
		{
			filename = '__PersonalTransformer2__/graphics/equipment/personal-transformer.png',
			width = 32,
			height = 32,
			priority = 'medium'
		},
		shape =
		{
			type = 'full',
			width = 2,
			height = 2
		},
		energy_source =
		{
			type = 'electric',
			buffer_capacity = '20kJ',
			input_flow_limit = '200kW',
			output_flow_limit = '200kW',
			usage_priority = 'tertiary'
		}
--		categories = { 'armor-transformer' }
	},
	
	["transformer-2"] = {
		type = 'battery-equipment',
		name = 'personal-transformer-mk2-equipment',
		sprite =
		{
			filename = '__PersonalTransformer2__/graphics/equipment/personal-transformer2.png',
			width = 32,
			height = 32,
			priority = 'medium'
		},
		shape =
		{
			type = 'full',
			width = 2,
			height = 2
		},
		energy_source =
		{
			type = 'electric',
			buffer_capacity = '100kJ',
			input_flow_limit = '1MW',
			output_flow_limit = '1MW',
			usage_priority = 'tertiary'
		}
--		categories = { 'armor-transformer' }
	},
	
	["transformer-3"] = {
		type = 'battery-equipment',
		name = 'personal-transformer-mk3-equipment',
		sprite =
		{
			filename = '__PersonalTransformer2__/graphics/equipment/personal-transformer3.png',
			width = 32,
			height = 32,
			priority = 'medium'
		},
		shape =
		{
			type = 'full',
			width = 2,
			height = 2
		},
		energy_source =
		{
			type = 'electric',
			buffer_capacity = '400kJ',
			input_flow_limit = '4MW',
			output_flow_limit = '4MW',
			usage_priority = 'tertiary'
		}
--		categories = { 'armor-transformer' }
	}
}

for name, teq in pairs(transformer_eq) do
--	log('\n\n')
--	log('TEQ: ')
--  log (serpent.block (teq))
	if settings.startup["personal-transformer2-allow-non-armor"].value then
		teq.categories = { 'armor' }
	else
		teq.categories = { 'armor-transformer' }
	end
--	log('\n\n')
--	log('TEQ2: ')
--  log (serpent.block (teq))

	data:extend({
		teq
	})
end



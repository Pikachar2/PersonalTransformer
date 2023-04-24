data:extend{
	{
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
		},
		categories = { 'armor' }
	},
	{
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
		},
		categories = { 'armor' }
	},
	{
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
		},
		categories = { 'armor' }
	}
}
data:extend{
	{
		type = 'recipe',
		name = 'personal-transformer-equipment',
		energy_required = 10,
		ingredients =
		{
			{ 'steel-plate', 10 },
			{ 'battery', 5 },
			{ 'copper-cable', 100 }
		},
		enabled = false,
		result = 'personal-transformer-equipment'
	},
	{
		type = 'recipe',
		name = 'personal-transformer-mk2-equipment',
		energy_required = 10,
		ingredients =
		{
			{ 'low-density-structure', 10 },
			{ 'processing-unit', 20 },
			{ 'personal-transformer-equipment', 5 }
		},
		enabled = false,
		result = 'personal-transformer-mk2-equipment'
	},
	{
		type = 'recipe',
		name = 'personal-transformer-mk3-equipment',
		energy_required = 10,
		ingredients =
		{
			{ 'low-density-structure', 50 },
			{ 'processing-unit', 100 },
			{ 'accumulator', 10 },
			{ 'personal-transformer-mk2-equipment', 5 }
		},
		enabled = false,
		result = 'personal-transformer-mk3-equipment'
	}
}
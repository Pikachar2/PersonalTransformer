data:extend{
	{
		type = 'technology',
		name = 'personal-transformer-equipment',
		icon = '__PersonalTransformer2__/graphics/technology/personal-transformer.png',
		icon_size = 256,
		unit =
		{
			count = 150,
			ingredients =
			{
				{ 'automation-science-pack', 1 },
				{ 'logistic-science-pack', 1 },
				{ 'chemical-science-pack', 1 }
			},
			time = 15
		},
		prerequisites = { 'solar-panel-equipment', 'battery', 'chemical-science-pack' },
		effects =
		{
			{
				type = 'unlock-recipe',
				recipe = 'personal-transformer-equipment'
			}
		}
	},
	{
		type = 'technology',
		name = 'personal-transformer-mk2-equipment',
		icon = '__PersonalTransformer2__/graphics/technology/personal-transformer2.png',
		icon_size = 256,
		unit =
		{
			count = 250,
			ingredients =
			{
				{ 'automation-science-pack', 1 },
				{ 'logistic-science-pack', 1 },
				{ 'chemical-science-pack', 1 },
				{ 'production-science-pack', 1 }
			},
			time = 30
		},
		prerequisites = { 'electric-energy-accumulators', 'low-density-structure', 'personal-transformer-equipment', 'production-science-pack' },
		effects =
		{
			{
				type = 'unlock-recipe',
				recipe = 'personal-transformer-mk2-equipment'
			}
		}
	},
	{
		type = 'technology',
		name = 'personal-transformer-mk3-equipment',
		icon = '__PersonalTransformer2__/graphics/technology/personal-transformer3.png',
		icon_size = 256,
		unit =
		{
			count = 500,
			ingredients =
			{
				{ 'automation-science-pack', 1 },
				{ 'logistic-science-pack', 1 },
				{ 'chemical-science-pack', 1 },
				{ 'production-science-pack', 1 },
				{ 'utility-science-pack', 1 }
			},
			time = 30
		},
		prerequisites = { 'personal-transformer-mk2-equipment', 'utility-science-pack' },
		effects =
		{
			{
				type = 'unlock-recipe',
				recipe = 'personal-transformer-mk3-equipment'
			}
		}
	}
}

if settings.startup["personal-transformer2-enable-research"].value then
	local bonus_val = settings.startup["personal-transformer2-research-bonus"].value
	local bonus_type = settings.startup["personal-transformer2-research-bonus-type"].value
	local cost_formula = settings.startup["personal-transformer2-research-cost-formula"].value

	local effect_key = (bonus_type == "flat")
		and "modifier-description.personal-transformer-efficiency-flat"
		or "modifier-description.personal-transformer-efficiency"

	data:extend{
		{
			type = 'technology',
			name = 'personal-transformer-efficiency',
			icons =
			{
				{
					icon = '__PersonalTransformer2__/graphics/technology/personal-transformer3.png',
					icon_size = 256
				},
				{
					icon = '__core__/graphics/icons/technology/constants/constant-capacity.png',
					icon_size = 128,
					scale = 0.5,
					shift = { 50, 50 }
				}
			},
			prerequisites = { 'personal-transformer-mk3-equipment', 'space-science-pack' },
			unit =
			{
				count_formula = cost_formula,
				ingredients =
				{
					{ 'automation-science-pack', 1 },
					{ 'logistic-science-pack', 1 },
					{ 'chemical-science-pack', 1 },
					{ 'production-science-pack', 1 },
					{ 'utility-science-pack', 1 },
					{ 'space-science-pack', 1 }
				},
				time = 60
			},
			effects =
			{
				{
					type = 'nothing',
					effect_description = { effect_key, tostring(bonus_val) }
				}
			},
			max_level = 'infinite',
			upgrade = true
		}
	}
end

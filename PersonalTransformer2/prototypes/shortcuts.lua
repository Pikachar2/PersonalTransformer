data:extend{
	{
		type = 'shortcut',
		name = 'toggle-equipment-transformer-input',
		order = 'c[toggle]-c[transformer-input]',
		action = 'lua',
		localised_name = { 'shortcut.toggle-equipment-transformer-input' },
		associated_control_input = 'toggle-equipment-transformer-input',
		technology_to_unlock = 'personal-transformer-equipment',
		toggleable = true,
		icon =
		{
			filename = '__PersonalTransformer2__/graphics/icons/shortcut-toolbar/personal-transformer-input-x32.png',
			priority = 'extra-high-no-scale',
			size = 32,
			scale = 1,
			flags = { 'icon' }
		},
		small_icon =
		{
			filename = '__PersonalTransformer2__/graphics/icons/shortcut-toolbar/personal-transformer-input-x24.png',
			priority = 'extra-high-no-scale',
			size = 24,
			scale = 1,
			flags = { 'icon' }
		},
		disabled_icon =
		{
			filename = '__PersonalTransformer2__/graphics/icons/shortcut-toolbar/personal-transformer-input-x32-white.png',
			priority = 'extra-high-no-scale',
			size = 32,
			scale = 1,
			flags = { 'icon' }
		},
		disabled_small_icon =
		{
			filename = '__PersonalTransformer2__/graphics/icons/shortcut-toolbar/personal-transformer-input-x24-white.png',
			priority = 'extra-high-no-scale',
			size = 24,
			scale = 1,
			flags = { 'icon' }
		}
	},
	{
		type = 'custom-input',
		name = 'personal-transformer-toggle-input',
		key_sequence = ''
	},
	{
		type = 'shortcut',
		name = 'toggle-equipment-transformer-output',
		order = 'c[toggle]-c[transformer-output]',
		action = 'lua',
		localised_name = { 'shortcut.toggle-equipment-transformer-output' },
		associated_control_input = 'toggle-equipment-transformer-output',
		technology_to_unlock = 'personal-transformer-equipment',
		toggleable = true,
		icon =
		{
			filename = '__PersonalTransformer2__/graphics/icons/shortcut-toolbar/personal-transformer-output-x32.png',
			priority = 'extra-high-no-scale',
			size = 32,
			scale = 1,
			flags = { 'icon' }
		},
		small_icon =
		{
			filename = '__PersonalTransformer2__/graphics/icons/shortcut-toolbar/personal-transformer-output-x24.png',
			priority = 'extra-high-no-scale',
			size = 24,
			scale = 1,
			flags = { 'icon' }
		},
		disabled_icon =
		{
			filename = '__PersonalTransformer2__/graphics/icons/shortcut-toolbar/personal-transformer-output-x32-white.png',
			priority = 'extra-high-no-scale',
			size = 32,
			scale = 1,
			flags = { 'icon' }
		},
		disabled_small_icon =
		{
			filename = '__PersonalTransformer2__/graphics/icons/shortcut-toolbar/personal-transformer-output-x24-white.png',
			priority = 'extra-high-no-scale',
			size = 24,
			scale = 1,
			flags = { 'icon' }
		}
	},
	{
		type = 'custom-input',
		name = 'personal-transformer-toggle-output',
		key_sequence = ''
	}
}
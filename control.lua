local char_armor_transformers = nil

script.on_init(function()
		char_armor_transformers = { }
		char_armor_transformers.trans = { }
		char_armor_transformers.trans2 = { }
		char_armor_transformers.trans3 = { }
		global.char_armor_transformers = char_armor_transformers
	end)

script.on_load(function()
		char_armor_transformers = global.char_armor_transformers
		if char_armor_transformers.trans == nil then
			char_armor_transformers.trans = { }
			char_armor_transformers.trans2 = { }
			char_armor_transformers.trans3 = { }
		end
	end)

script.on_event(defines.events.on_lua_shortcut,
	function(event)
		if event.prototype_name == 'toggle-equipment-transformer-input' then
			local player = game.players[event.player_index]
			player.set_shortcut_toggled('toggle-equipment-transformer-input', not player.is_shortcut_toggled('toggle-equipment-transformer-input'))
		elseif event.prototype_name == 'toggle-equipment-transformer-output' then
			local player = game.players[event.player_index]
			player.set_shortcut_toggled('toggle-equipment-transformer-output', not player.is_shortcut_toggled('toggle-equipment-transformer-output'))
		end
	end)

script.on_event(defines.events.on_tick,
	function(event)
	
		-- This is a delay constant for controlling how often the transformer script runs. The mod will behave reasonably for any value from 1 to 6.
		-- Lower values are more UPS intensive but have finer updates, while higher values are less UPS intensive but have coarser updates.
		local tickdelay = 1
		
		if event.tick % tickdelay ~= 0 then
			return
		end
		update_personal_transformer(tickdelay, char_armor_transformers.trans, 'personal-transformer-equipment', 'personal-transformer-input-entity', 'personal-transformer-output-entity', 200000)
		update_personal_transformer(tickdelay, char_armor_transformers.trans2, 'personal-transformer-mk2-equipment', 'personal-transformer-mk2-input-entity', 'personal-transformer-mk2-output-entity', 1000000)
		update_personal_transformer(tickdelay, char_armor_transformers.trans3, 'personal-transformer-mk3-equipment', 'personal-transformer-mk3-input-entity', 'personal-transformer-mk3-output-entity', 4000000)
	end)

function update_personal_transformer(tickdelay, char_table, equip_name, input_name, output_name, max_draw)
	local dt = tickdelay / 60
	local buffer = max_draw / 10
	local _, p, t, v, grid = nil
	for _, p in pairs(game.players) do
		if p.character ~= nil then
			t = char_table[p.index]
			grid = p.character.grid
			if grid ~= nil then
				if t == nil then
					t =
					{
						inputs = { },
						outputs = { }
					}
					char_table[p.index] = t
				end
				t.has_player = true
				local transformer_count = 0
				local max_draw_in = 0
				local max_draw_out = 0
				for _, v in pairs(grid.equipment) do
					if v.name == equip_name then
						transformer_count = transformer_count + 1
					elseif v.prototype.energy_source ~= nil then
						local draw_in = math.min(v.prototype.energy_source.input_flow_limit * tickdelay, v.prototype.energy_source.buffer_capacity - v.energy)
						local draw_out = math.min(v.prototype.energy_source.output_flow_limit * tickdelay, v.energy)
						max_draw_in = max_draw_in + draw_in
						max_draw_out = max_draw_out + draw_out
					end
				end
				if not p.is_shortcut_toggled('toggle-equipment-transformer-input') then
					max_draw_in = 0
				end
				if not p.is_shortcut_toggled('toggle-equipment-transformer-output') then
					max_draw_out = 0
				end
				local pos = p.position
				if transformer_count ~= #t.outputs then
					while transformer_count < #t.outputs do
						t.inputs[#t.outputs].destroy()
						t.inputs[#t.outputs] = nil
						t.outputs[#t.outputs].destroy()
						t.outputs[#t.outputs] = nil
					end
					while transformer_count > #t.outputs do
						table.insert(t.inputs, p.surface.create_entity
						{
							name = input_name,
							position = pos,
							force = p.force
						})
						table.insert(t.outputs, p.surface.create_entity
						{
							name = output_name,
							position = pos,
							force = p.force
						})
					end
				end
				if transformer_count ~= 0 then
					local avail_in = 0
					local request_out = 0
					for _, v in pairs(t.inputs) do
						if not v.valid then
							v = p.surface.create_entity
							{
								name = input_name,
								position = pos,
								force = p.force
							}
							t[_] = v
						end
						v.teleport(pos)
						avail_in = avail_in + v.energy
					end
					for _, v in pairs(t.outputs) do
						if not v.valid then
							v = p.surface.create_entity
							{
								name = output_name,
								position = pos,
								force = p.force
							}
							t[_] = v
						end
						v.teleport(pos)
						request_out = request_out + (buffer - v.energy)
					end
					local drain_in, drain_out, ratio_in, ratio_out = nil
					if avail_in == 0 then
						drain_in = 0
					else
						drain_in = math.min(math.max(max_draw_in / avail_in, 0), 1)
					end
					if request_out == 0 then
						drain_out = 0
					else
						drain_out = math.min(math.max(max_draw_out / request_out, 0), 1)
					end
					avail_in = math.min(avail_in, max_draw * transformer_count * dt)
					request_out = math.min(request_out, max_draw * transformer_count * dt)
					if max_draw_in == 0 then
						ratio_in = 0
					else
						ratio_in = math.min(math.max(avail_in / max_draw_in, 0), 1)
					end
					if max_draw_out == 0 then
						ratio_out = 0
					else
						ratio_out = math.min(math.max(request_out / max_draw_out, 0), 1)
					end
					for _, v in pairs(t.inputs) do
						v.energy = v.energy * (1 - drain_in)
					end
					for _, v in pairs(t.outputs) do
						v.energy = buffer - ((buffer - v.energy) * (1 - drain_out))
					end
					for _, v in pairs(grid.equipment) do
						if v.name ~= equip_name and v.prototype.energy_source ~= nil then
							local draw_in = math.min(v.prototype.energy_source.input_flow_limit * tickdelay, v.prototype.energy_source.buffer_capacity - v.energy)
							local draw_out = math.min(v.prototype.energy_source.output_flow_limit * tickdelay, v.energy)
							local dE = draw_in * ratio_in - draw_out * ratio_out
							v.energy = v.energy + dE
						end
					end
				end
			end
		end
	end
	for v, t in pairs(char_table) do
		if not t.has_player then
			char_table[v] = nil
			for _, v in pairs(t.inputs) do
				v.destroy()
			end
			for _, v in pairs(t.outputs) do
				v.destroy()
			end
		else
			t.has_player = false
		end
	end
end
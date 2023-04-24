local char_armor_transformers = nil
local vehicle_armor_transformers = nil

local tickdelay = 1

local mk1_draw = 200000
local mk2_draw = 1000000
local mk3_draw = 4000000

local personal_transformer_mk1_name = "personal-transformer-equipment"
local personal_transformer_mk2_name = "personal-transformer-mk2-equipment"
local personal_transformer_mk3_name = "personal-transformer-mk3-equipment"

global.grid_vehicles = global.grid_vehicles or {}
global.grid_draw = global.grid_draw or {}
global.grid_transformer_entities = global.grid_transformer_entities or {}
global.grid_energy_draw = global.grid_energy_draw or {}


script.on_init(
	function()
		char_armor_transformers = { }
		char_armor_transformers.trans = { }
		char_armor_transformers.trans2 = { }
		char_armor_transformers.trans3 = { }
		global.char_armor_transformers = char_armor_transformers
		
		global.grid_vehicles = global.grid_vehicles or {}
		global.grid_draw = global.grid_draw or {}
		global.grid_transformer_entities = global.grid_transformer_entities or {}
		global.grid_energy_draw = global.grid_energy_draw or {}

	end
)

script.on_load(
	function()
		char_armor_transformers = global.char_armor_transformers
		if char_armor_transformers.trans == nil then
			char_armor_transformers.trans = { }
			char_armor_transformers.trans2 = { }
			char_armor_transformers.trans3 = { }
		end
	end
)


script.on_configuration_changed(
	function(data)
		log ('migrations starting...')
		for s, surface in pairs(game.surfaces) do
			for v, vehicle in pairs(surface.find_entities_filtered{type = my_types}) do
				grid = vehicle.grid
				if grid and grid.valid then
					global.grid_vehicles[grid.unique_id] = vehicle
				end
			end
		end
		log ('global.grid_vehicles = '.. serpent.dump(global.grid_vehicles))
	end
)


script.on_event(defines.events.on_equipment_inserted,
	function(event)
		local grid_id = event.grid.unique_id
		local valid_vehicle =  global.grid_vehicles[grid_id] -- and global.grid_vehicles[grid_id].entity
		local vehicle = nil
		
		if valid_vehicle and valid_vehicle.valid then
			vehicle = global.grid_vehicles[grid_id]

			add_grid_draw(event.equipment.name, grid_id, personal_transformer_mk1_name, mk1_draw)
			add_grid_draw(event.equipment.name, grid_id, personal_transformer_mk2_name, mk2_draw)
			add_grid_draw(event.equipment.name, grid_id, personal_transformer_mk3_name, mk3_draw)
		end
		
		if not global.grid_transformer_entities[grid_id] then
			local entity = vehicle.surface.create_entity
				{
					name = "personal-transformer-input-entity",
					position = vehicle.position,
					force = vehicle.force
				}
--			entity.energy_source.input_flow_limit = '300kW'
			global.grid_transformer_entities[grid_id] = entity
		end

		global.grid_energy_draw[grid_id] = get_grid_energy_draw(event.grid)
		
	end
)

script.on_event(defines.events.on_equipment_removed,
	function(event)
		local grid_id = event.grid.unique_id
		local valid_vehicle =  global.grid_vehicles[grid_id] -- and global.grid_vehicles[grid_id].entity
		local vehicle = nil

		if valid_vehicle and valid_vehicle.valid then
			subtract_grid_draw(event.equipment, grid_id, personal_transformer_mk1_name, mk1_draw)
			subtract_grid_draw(event.equipment, grid_id, personal_transformer_mk2_name, mk2_draw)
			subtract_grid_draw(event.equipment, grid_id, personal_transformer_mk3_name, mk3_draw)
		end
		
		if not global.grid_draw[grid_id] then
			global.grid_transformer_entities[grid_id].destroy()
			global.grid_transformer_entities[grid_id] = nil
		end
		
	end
)

script.on_event(defines.events.on_built_entity, 
	function(event)
	-- add placed vehicle to vehicle list
	-- add draw total to draw list
	log ('global.grid_vehicles = '.. serpent.block(global.grid_vehicles))
	print ('onBuiltEvent = '.. serpent.block(event))
	log ('onBuiltEvent = '.. serpent.block(event))
		local vehicle = event.created_entity
	log ('entity = '.. serpent.block(vehicle))
	log ('vehicle name = '.. serpent.block(vehicle.name))
		local grid = vehicle.grid
		if grid and grid.valid then
	log ('vehicle grid ID = '.. serpent.block(grid.unique_id))
			global.grid_vehicles[grid.unique_id] = vehicle
			local mk1_count = grid.count(personal_transformer_mk1_name)
			local mk2_count = grid.count(personal_transformer_mk2_name)
			local mk3_count = grid.count(personal_transformer_mk3_name)
			local draw_total = (mk1_count * mk1_draw) + (mk2_count * mk2_draw) + (mk3_count * mk3_draw)
			if draw_total > 0 then
				global.grid_draw[grid.unique_id] = draw_total
			end
		end
	log ('post IF')
	log ('global.grid_vehicles = '.. serpent.block(global.grid_vehicles[grid.unique_id]))
	print ('global.grid_vehicles = '.. serpent.block(global.grid_vehicles[grid.unique_id]))
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

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
		update_personal_transformer(tickdelay, char_armor_transformers.trans, 'personal-transformer-equipment', 'personal-transformer-input-entity', 'personal-transformer-output-entity', mk1_draw)
		update_personal_transformer(tickdelay, char_armor_transformers.trans2, 'personal-transformer-mk2-equipment', 'personal-transformer-mk2-input-entity', 'personal-transformer-mk2-output-entity', mk2_draw)
		update_personal_transformer(tickdelay, char_armor_transformers.trans3, 'personal-transformer-mk3-equipment', 'personal-transformer-mk3-input-entity', 'personal-transformer-mk3-output-entity', mk3_draw)

		update_vehicle_transformer(tickdelay, 'personal-transformer-equipment', 'personal-transformer-input-entity', 'personal-transformer-output-entity', mk1_draw)
		update_vehicle_transformer(tickdelay, 'personal-transformer-mk2-equipment', 'personal-transformer-mk2-input-entity', 'personal-transformer-mk2-output-entity', mk2_draw)
		update_vehicle_transformer(tickdelay, 'personal-transformer-mk3-equipment', 'personal-transformer-mk3-input-entity', 'personal-transformer-mk3-output-entity', mk3_draw)

	end)

function update_personal_transformer(tickdelay, char_table, equip_name, input_name, output_name, max_draw)
	local dt = tickdelay / 60
	local buffer = max_draw / 10
	local _, p, t, v, grid = nil
	for _, p in pairs(game.players) do
	-- p is player
	-- t is character
	-- v is various
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
					-- create count of transformer type
						transformer_count = transformer_count + 1
					elseif v.prototype.energy_source ~= nil then
						-- else if energy source calculate max_draw_in/out from equipment with flow limit
						-- ie, what's the flow rate of the generators/batteries
						local draw_in = math.min(v.prototype.energy_source.input_flow_limit * tickdelay, v.prototype.energy_source.buffer_capacity - v.energy)
						local draw_out = math.min(v.prototype.energy_source.output_flow_limit * tickdelay, v.energy)
						max_draw_in = max_draw_in + draw_in
						max_draw_out = max_draw_out + draw_out
					end
				end
				-- toggle off appropriate draw if toggle is off
				if not p.is_shortcut_toggled('toggle-equipment-transformer-input') then
					max_draw_in = 0
				end
				if not p.is_shortcut_toggled('toggle-equipment-transformer-output') then
					max_draw_out = 0
				end
				-- get position of entity
				local pos = p.position
				-- cleans up old personal-transformer-input/output entities
				if transformer_count ~= #t.outputs then
					while transformer_count < #t.outputs do
						t.inputs[#t.outputs].destroy()
						t.inputs[#t.outputs] = nil
						t.outputs[#t.outputs].destroy()
						t.outputs[#t.outputs] = nil
					end
					-- creates new personal-transformer-input/output entities
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
					-- creates new personal-transformer-input entities
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
					-- creates new personal-transformer-output entities
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
	-- cleans up character if there's no player
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


function update_vehicle_transformer(tickdelay, equip_name, input_name, output_name, max_draw)
	-- for each vehicle in global.grid_draw
	-- get position of each vehicle
	-- do the thing

	for grid_draw_id, grid_draw_value in pairs(global.grid_draw) do
		local vehicle_position = global.grid_vehicles[grid_draw_id].position
		-- if in appropriate position ie, in pole area
			-- do the thing
		-- else destroy invisible transformer entities
		local dt = tickdelay / 60
		local buffer = grid_draw_value / 10
		grid_transformer_entities.teleport(vehicle_position)
		
		local grid_entity = global.grid_transformer_entities[grid_draw_id]

		local avail_in = grid_entity.energy
		local request_out = buffer - grid_entity.energy

		local max_draw_in = global.grid_energy_draw[max_draw_in]
		local max_draw_out = global.grid_energy_draw[max_draw_out]
		
		local transformer_count = 1


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
		-- for _, v in pairs(t.inputs) do
			grid_entity.energy = grid_entity.energy * (1 - drain_in)
		-- end
		-- for _, v in pairs(t.outputs) do
			grid_entity.energy = buffer - ((buffer - grid_entity.energy) * (1 - drain_out))
		-- end
		for _, v in pairs(grid.equipment) do
			if not is_personal_transformer_name_match(v.name) and v.prototype.energy_source ~= nil then
				local draw_in = math.min(v.prototype.energy_source.input_flow_limit * tickdelay, v.prototype.energy_source.buffer_capacity - v.energy)
				local draw_out = math.min(v.prototype.energy_source.output_flow_limit * tickdelay, v.energy)
				local dE = draw_in * ratio_in - draw_out * ratio_out
				v.energy = v.energy + dE
			end
		end
		
	end


--- old code
	-- local dt = tickdelay / 60
	-- local buffer = max_draw / 10
	-- local _, p, t, v, grid = nil
	-- for _, p in pairs(game.players) do
	-- -- p is player
	-- -- t is character
	-- -- v is various
		-- if p.character ~= nil then
			-- t = char_table[p.index]
			-- grid = p.character.grid
			-- if grid ~= nil then
				-- if t == nil then
					-- t =
					-- {
						-- inputs = { },
						-- outputs = { }
					-- }
					-- char_table[p.index] = t
				-- end
				-- t.has_player = true
				-- local transformer_count = 0
				-- local max_draw_in = 0
				-- local max_draw_out = 0
				-- for _, v in pairs(grid.equipment) do
					-- if v.name == equip_name then
					-- -- create count of transformer type
						-- transformer_count = transformer_count + 1
					-- elseif v.prototype.energy_source ~= nil then
						-- -- else if energy source calculate max_draw_in/out from equipment with flow limit
						-- -- ie, what's the flow rate of the generators/batteries
						-- local draw_in = math.min(v.prototype.energy_source.input_flow_limit * tickdelay, v.prototype.energy_source.buffer_capacity - v.energy)
						-- local draw_out = math.min(v.prototype.energy_source.output_flow_limit * tickdelay, v.energy)
						-- max_draw_in = max_draw_in + draw_in
						-- max_draw_out = max_draw_out + draw_out
					-- end
				-- end
				-- -- toggle off appropriate draw if toggle is off
				-- if not p.is_shortcut_toggled('toggle-equipment-transformer-input') then
					-- max_draw_in = 0
				-- end
				-- if not p.is_shortcut_toggled('toggle-equipment-transformer-output') then
					-- max_draw_out = 0
				-- end
				-- -- get position of entity
				-- local pos = p.position
				-- -- cleans up old personal-transformer-input/output entities
				-- if transformer_count ~= #t.outputs then
					-- while transformer_count < #t.outputs do
						-- t.inputs[#t.outputs].destroy()
						-- t.inputs[#t.outputs] = nil
						-- t.outputs[#t.outputs].destroy()
						-- t.outputs[#t.outputs] = nil
					-- end
					-- -- creates new personal-transformer-input/output entities
					-- while transformer_count > #t.outputs do
						-- table.insert(t.inputs, p.surface.create_entity
						-- {
							-- name = input_name,
							-- position = pos,
							-- force = p.force
						-- })
						-- table.insert(t.outputs, p.surface.create_entity
						-- {
							-- name = output_name,
							-- position = pos,
							-- force = p.force
						-- })
					-- end
				-- end
				-- if transformer_count ~= 0 then
					-- local avail_in = 0
					-- local request_out = 0
					-- -- creates new personal-transformer-input entities
					-- for _, v in pairs(t.inputs) do
						-- if not v.valid then
							-- v = p.surface.create_entity
							-- {
								-- name = input_name,
								-- position = pos,
								-- force = p.force
							-- }
							-- t[_] = v
						-- end
						-- v.teleport(pos)
						-- avail_in = avail_in + v.energy
					-- end
					-- -- creates new personal-transformer-output entities
					-- for _, v in pairs(t.outputs) do
						-- if not v.valid then
							-- v = p.surface.create_entity
							-- {
								-- name = output_name,
								-- position = pos,
								-- force = p.force
							-- }
							-- t[_] = v
						-- end
						-- v.teleport(pos)
						-- request_out = request_out + (buffer - v.energy)
					-- end
					-- local drain_in, drain_out, ratio_in, ratio_out = nil
					-- if avail_in == 0 then
						-- drain_in = 0
					-- else
						-- drain_in = math.min(math.max(max_draw_in / avail_in, 0), 1)
					-- end
					-- if request_out == 0 then
						-- drain_out = 0
					-- else
						-- drain_out = math.min(math.max(max_draw_out / request_out, 0), 1)
					-- end
					-- avail_in = math.min(avail_in, max_draw * transformer_count * dt)
					-- request_out = math.min(request_out, max_draw * transformer_count * dt)
					-- if max_draw_in == 0 then
						-- ratio_in = 0
					-- else
						-- ratio_in = math.min(math.max(avail_in / max_draw_in, 0), 1)
					-- end
					-- if max_draw_out == 0 then
						-- ratio_out = 0
					-- else
						-- ratio_out = math.min(math.max(request_out / max_draw_out, 0), 1)
					-- end
					-- for _, v in pairs(t.inputs) do
						-- v.energy = v.energy * (1 - drain_in)
					-- end
					-- for _, v in pairs(t.outputs) do
						-- v.energy = buffer - ((buffer - v.energy) * (1 - drain_out))
					-- end
					-- for _, v in pairs(grid.equipment) do
						-- if v.name ~= equip_name and v.prototype.energy_source ~= nil then
							-- local draw_in = math.min(v.prototype.energy_source.input_flow_limit * tickdelay, v.prototype.energy_source.buffer_capacity - v.energy)
							-- local draw_out = math.min(v.prototype.energy_source.output_flow_limit * tickdelay, v.energy)
							-- local dE = draw_in * ratio_in - draw_out * ratio_out
							-- v.energy = v.energy + dE
						-- end
					-- end
				-- end
			-- end
		-- end
	-- end
	-- -- cleans up character if there's no player
	-- for v, t in pairs(char_table) do
		-- if not t.has_player then
			-- char_table[v] = nil
			-- for _, v in pairs(t.inputs) do
				-- v.destroy()
			-- end
			-- for _, v in pairs(t.outputs) do
				-- v.destroy()
			-- end
		-- else
			-- t.has_player = false
		-- end
	-- end
end

function add_grid_draw(equipment_name, grid_id, transformer_name, draw)
	if equipment_name:find(transformer_name) then
		if global.grid_draw[grid_id] then
			global.grid_draw[grid_id] = global.grid_draw[grid_id] + draw
		else
			global.grid_draw[grid_id] = draw
		end
	end
end

function subtract_grid_draw(equipment_name, grid_id, transformer_name, draw)
	if equipment_name:find(transformer_name) then
		if global.grid_draw[grid_id] then
			global.grid_draw[grid_id] = global.grid_draw[grid_id] - draw
			if global.grid_draw[grid_id] <= 0 then
				global.grid_draw[grid_id] = nil
			end
		end
	end
end

function get_grid_energy_draw(grid)
	local max_draw_in = 0
	local max_draw_out = 0

	for _, equipment in pairs(grid.equipment) do
		if not is_personal_transformer_name_match(equipment.name) and equipment.prototype.energy_source ~= nil then
			-- else if energy source calculate max_draw_in/out from equipment with flow limit
			-- ie, what's the flow rate of the generators/batteries
			local draw_in = math.min(equipment.prototype.energy_source.input_flow_limit * tickdelay, equipment.prototype.energy_source.buffer_capacity - equipment.energy)
			local draw_out = math.min(equipment.prototype.energy_source.output_flow_limit * tickdelay, equipment.energy)
			max_draw_in = max_draw_in + draw_in
			max_draw_out = max_draw_out + draw_out
		end
	end
	local max_draw = {}
	max_draw["max_draw_in"] = max_draw_in
	max_draw["max_draw_out"] = max_draw_out
	return max_draw
end

function is_personal_transformer_name_match(name)
	return name == personal_transformer_mk1_name or name == personal_transformer_mk2_name or name == personal_transformer_mk3_name
end



local char_armor_transformers = nil
local vehicle_armor_transformers = nil
local my_types = {"car", "spider-vehicle", "rolling-stock"}

-- This is a delay constant for controlling how often the transformer script runs. The mod will behave reasonably for any value from 1 to 6.
-- Lower values are more UPS intensive but have finer updates, while higher values are less UPS intensive but have coarser updates.
local tickdelay = settings.global["personal-transformer2-tick-delay"].value

local mk1_draw = 200000
local mk2_draw = 1000000
local mk3_draw = 4000000

-- grid_owner_type can be "player", "entity", "item"

local personal_transformer_mk1_name = "personal-transformer-equipment"
local personal_transformer_mk2_name = "personal-transformer-mk2-equipment"
local personal_transformer_mk3_name = "personal-transformer-mk3-equipment"
local isVehicleGridAllowed = settings.startup["personal-transformer2-allow-non-armor"].value;

local transformer_draw = {}
transformer_draw[personal_transformer_mk1_name] = mk1_draw
transformer_draw[personal_transformer_mk2_name] = mk2_draw
transformer_draw[personal_transformer_mk3_name] = mk3_draw


global.grid_vehicles = global.grid_vehicles or {}
global.transformer_data = global.transformer_data or {}
	-- global.transformer_data[grid_id] = {
		-- grid_draw = someNum,
		-- grid_transformer_entities = {list of transformer entities},
		-- transformer_count[level] = someNum
		-- equipment_draw_in = someNum,
		-- equipment_draw_out = someNum,
		-- item3 = {}....
	-- }



--[[
	global.transformer_data[grid_id] = {
		grid_transformer_entities = {list of transformer entities},
		transformer_count[level] = someNum
		grid_owner_id = someNum
		grid_owner_type = player/entity
		max_grid_draw = someNum
		buffer = max_grid_draw/10
	}
--]]



--[[ 
	global.char_armor_transformers[player_id] = {
		trans_mk1 = { *each is PT*}
		trans_mk2 = { }
		trans_mk3 = { }

		--// What each of the mkx look like
		pt =
		{
			inputs = { },
			outputs = { },
			count = 0
		}


	}
--]]

--[[
	pt =
	{
		inputs = { },
		outputs = { },
		count = 0
	}
	t =
	{
		trans_mk1 = { }
		trans_mk2 = { }
		trans_mk3 = { }
	}
	char_table[p.index] = t
--]]


script.on_init(
	function()
		char_armor_transformers = { }
		global.char_armor_transformers = char_armor_transformers

		global.transformer_data = global.transformer_data or {}
		-- log ('init --- global.transformer_data = '.. serpent.dump(global.transformer_data))
		-- I don't like this, but it wont work in on_init for some reason... need to figure that out once the rest is working
		if global.transformer_data == nil then
			global.transformer_data = {}
		end

		global.grid_vehicles = global.grid_vehicles or {}
	end
)

script.on_load(
	function()
		char_armor_transformers = global.char_armor_transformers
--[[
		if char_armor_transformers.trans == nil then
			char_armor_transformers.trans = { }
			char_armor_transformers.trans2 = { }
			char_armor_transformers.trans3 = { }
		end
--]]
	end
)

script.on_configuration_changed(
	function(data)
	-- global.grid_vehicles = {}
		log ('on_configuration_changed --- migrations starting...')
		log ('on_configuration_changed start --- global.grid_vehicles = '.. serpent.block(global.grid_vehicles))
		if global.transformer_data == nil then
			global.transformer_data = {}
		end
		for s, surface in pairs(game.surfaces) do
			for v, vehicle in pairs(surface.find_entities_filtered{type = my_types}) do
				if vehicle and vehicle.valid then
					log ('on_configuration_changed valid vehicle --- vehicle.unit_number: ' .. serpent.block(vehicle.unit_number))
					grid = vehicle.grid
					if grid and grid.valid then
						global.grid_vehicles[grid.unique_id] = vehicle
					end
				end
			end
		end
		log ('on_configuration_changed end --- global.transformer_data = '.. serpent.block(global.transformer_data))
		log ('on_configuration_changed end --- global.grid_vehicles = '.. serpent.block(global.grid_vehicles))
	end
)


script.on_event(defines.events.on_equipment_inserted,
	function(event)
-- CHARACTER CODE
		log ('on_equipment_inserted start --- ')
	local grid_id = event.grid.unique_id
	local player = isPlayerOwnerOfGrid(grid_id)
	
	if player ~= nil then
		equipmentInserted(player, grid_id, event.equipment.name)
		return
	end


-- VEHICLE CODE
		if not isVehicleGridAllowed then
			return
		end
		local valid_vehicle =  global.grid_vehicles[grid_id] -- and global.grid_vehicles[grid_id].entity
		local vehicle = nil
		
		if valid_vehicle and valid_vehicle.valid then
			if is_personal_transformer_name_match(event.equipment.name) then
				vehicle = global.grid_vehicles[grid_id]
				
				if not global.transformer_data[grid_id] then 
					global.transformer_data[grid_id] = {}
					global.transformer_data[grid_id].grid_transformer_entities = {}
				end
				
				add_grid_draw(event.equipment.name, grid_id, personal_transformer_mk1_name, mk1_draw)
				add_grid_draw(event.equipment.name, grid_id, personal_transformer_mk2_name, mk2_draw)
				add_grid_draw(event.equipment.name, grid_id, personal_transformer_mk3_name, mk3_draw)

				log ('on_inserted valid_vehicle --- global.transformer_data: ' .. serpent.block(global.transformer_data))
				insert_entity(event.equipment.name, vehicle, grid_id)
			end
			get_grid_energy_draw(event.grid)
		end

		log ('on_inserted end --- global.transformer_data: ' .. serpent.block(global.transformer_data))
	end
)

script.on_event(defines.events.on_equipment_removed,
	function(event)
		log ('on_equipment_removed start --- ')
		local grid_id = event.grid.unique_id
		if global.transformer_data[grid_id] == nil then
			return
		end

		if global.transformer_data[grid_id].grid_owner_type == "player" or global.transformer_data[grid_id].grid_owner_type == nil then
			equipmentRemoved(grid_id, event.equipment, event.count)
			return
		end
	
	-- VEHICLE CODE
		if not isVehicleGridAllowed then
			return
		end
		local valid_vehicle =  global.grid_vehicles[grid_id] -- and global.grid_vehicles[grid_id].entity
		local vehicle = nil

		if valid_vehicle and valid_vehicle.valid then
			if is_personal_transformer_name_match(event.equipment) then
				subtract_grid_draw(event.equipment, grid_id, personal_transformer_mk1_name, mk1_draw)
				subtract_grid_draw(event.equipment, grid_id, personal_transformer_mk2_name, mk2_draw)
				subtract_grid_draw(event.equipment, grid_id, personal_transformer_mk3_name, mk3_draw)

				remove_entity(event.equipment, grid_id)
				log ('on_removed post remove entity --- global.transformer_data: ' .. serpent.block(global.transformer_data))
				if global.transformer_data[grid_id].grid_draw == nil then
					log ('on_removed nil grid_draw --- global.transformer_data: ')
					global.transformer_data[grid_id] = nil
				end
			end

			get_grid_energy_draw(event.grid)
		end
		log ('on_removed end --- global.transformer_data: ' .. serpent.block(global.transformer_data))
	end
)


script.on_event(defines.events.on_player_placed_equipment, 
	function(event)
		log ('on_player_placed_equipment start --- ')
		-- remove all transformer I/O entities
		-- Check grid index against player's currently equipped armor?
		-- Add entities for new armor if need be
		
		
	end
)


script.on_event(defines.events.on_player_removed_equipment, 
	function(event)
		log ('on_player_removed_equipment start --- ')
		-- remove all transformer I/O entities
		-- Check grid index against player's currently equipped armor?
		-- Add entities for new armor if need be
		
		
	end
)

script.on_event(defines.events.on_built_entity, 
	function(event)
		new_vehicle_placed_event_wrapper(event)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_robot_built_entity, 
	function(event)
		new_vehicle_placed_event_wrapper(event)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_entity_cloned, 
	function(event)
		new_vehicle_placed(event.destination)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.script_raised_built, 
	function(event)
		new_vehicle_placed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.script_raised_revive, 
	function(event)
		new_vehicle_placed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_player_mined_entity, 
	function(event)
--		log ('on_player_mined_entity start --- ')
		entity_removed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_robot_mined_entity, 
	function(event)
--		log ('on_robot_mined_entity start --- ')
		entity_removed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_entity_destroyed, 
	function(event)
		-- entity_removed(event.entity)
--	log ('on_entity_destroyed --- ')
	end

	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_entity_died, 
	function(event)
--		log ('on_entity_died start --- ')
		entity_removed(event.entity)
--		log ('on_entity_died end --- ')
	end

	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.script_raised_destroy, 
	function(event)
--		log ('script_raised_destroy start --- ')
		entity_removed(event.entity)
--		log ('script_raised_destroy end --- ')
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_player_changed_surface, 
	function(event)
		log ('on_player_changed_surface start --- ')
		removeInputOutputTransformerEntities(event.player_index, event.surface_index, global.char_armor_transformers.trans)
		removeInputOutputTransformerEntities(event.player_index, event.surface_index, global.char_armor_transformers.trans2)
		removeInputOutputTransformerEntities(event.player_index, event.surface_index, global.char_armor_transformers.trans3)
	end
)

script.on_event(defines.events.on_player_armor_inventory_changed, 
	function(event)
log ('on_player_armor_inventory_changed --- global.transformer_data: ' .. serpent.block(global.transformer_data))

		-- Search table for previously equipped armor and remove it from the table
		for grid_id, transformer_data_values in pairs(global.transformer_data) do
			if transformer_data_values.grid_owner_type == "player" and transformer_data_values.grid_owner_id == event.player_index then
				for count_key, count_value in pairs(transformer_data_values.transformer_count) do
					equipmentRemoved(grid_id, count_key, count_value)
				end
			end
		end
log ('on_player_armor_inventory_changed --- POST REMOVAL --- global.transformer_data: ' .. serpent.block(global.transformer_data))

		local player = game.players[event.player_index]
		if player.character ~= nil then
			local grid = player.character.grid
			if grid ~= nil then
				local current_grid_id = player.character.grid.unique_id
				
				-- Get Number of PTs in new armor and add them all to the table
				-- prolly need to null check character and grid
				local mk1_count = grid.count(personal_transformer_mk1_name)
				local mk2_count = grid.count(personal_transformer_mk2_name)
				local mk3_count = grid.count(personal_transformer_mk3_name)

				for i = 1, mk1_count do
					equipmentInserted(player, current_grid_id, personal_transformer_mk1_name)
				end
				for i = 1, mk2_count do
					equipmentInserted(player, current_grid_id, personal_transformer_mk2_name)
				end
				for i = 1, mk3_count do
					equipmentInserted(player, current_grid_id, personal_transformer_mk3_name)
				end

			end
		end
log ('on_player_armor_inventory_changed --- END --- global.transformer_data: ' .. serpent.block(global.transformer_data))
	end
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
		
		tickdelay = settings.global["personal-transformer2-tick-delay"].value

		if event.tick % tickdelay ~= 0 then
			return
		end
		update_personal_transformer(tickdelay, global.transformer_data)

--		update_vehicle_transformer()

	end)

function update_personal_transformer(tickdelay, transformer_data)
	local dt = tickdelay / 60
	for grid_id, transformer_data_values in pairs(global.transformer_data) do
		if transformer_data_values.grid_owner_type == "player" then
			local max_draw = transformer_data_values.max_grid_draw
			local buffer = transformer_data_values.buffer
			local player = game.players[transformer_data_values.grid_owner_id]

			local max_draw_in = 0
			local max_draw_out = 0

			-- If a player has both toggles off, no need to check anything.
			if not player.is_shortcut_toggled('toggle-equipment-transformer-input') and not player.is_shortcut_toggled('toggle-equipment-transformer-output') then
				goto continue
			end

			if player.character ~= nil then
				-- teleport entities to player
				teleportEntitiesToPlayerPosition(player.position, transformer_data_values.grid_transformer_entities)
				local grid = player.character.grid
				if grid ~= nil then
				-- perform math
					for _, v in pairs(grid.equipment) do
						if not is_personal_transformer_name_match(v.name) and v.prototype.energy_source ~= nil then
							-- if energy source calculate max_draw_in/out from equipment with flow limit
							-- ie, what's the flow rate of the generators/batteries
							-- toggle off appropriate draw if toggle is off
							if player.is_shortcut_toggled('toggle-equipment-transformer-input') then
								local draw_in = math.min(v.prototype.energy_source.input_flow_limit * tickdelay, v.prototype.energy_source.buffer_capacity - v.energy)
								max_draw_in = max_draw_in + draw_in
							else
								max_draw_in = 0
							end
							if player.is_shortcut_toggled('toggle-equipment-transformer-output') then
								local draw_out = math.min(v.prototype.energy_source.output_flow_limit * tickdelay, v.energy)
								max_draw_out = max_draw_out + draw_out
							else
								max_draw_out = 0
							end
						end
					end

					-- might wrap this in with the teleport to reduce amount of looping
					local avail_in = 0
					local request_out = 0
					for _, pt_entity in pairs(transformer_data_values.grid_transformer_entities) do
						if pt_entity.type == 'electric-energy-interface' then
							avail_in = avail_in + pt_entity.energy
						else
							request_out = request_out - pt_entity.energy
						end
					end
					request_out = request_out + buffer

					-- Power Calculations begin.
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
					avail_in = math.min(avail_in, max_draw * dt)
					request_out = math.min(request_out, max_draw * dt)
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
					-----
					for _, gt_entity in pairs(transformer_data_values.grid_transformer_entities) do
						if gt_entity.type == 'electric-energy-interface' then
							gt_entity.energy = gt_entity.energy * (1 - drain_in)
						else
							gt_entity.energy = buffer - ((buffer - gt_entity.energy) * (1 - drain_out))
						end
					end
					----
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
		::continue::
	end
end

function update_vehicle_transformer()
	-- for each grid in global.transformer_data
	-- get position of each vehicle
	-- do the thing

	-- log ('update_vehicle_transformer  --- global.transformer_data: ' .. serpent.block(global.transformer_data))
	-- log ('update_vehicle_transformer')
	if global.transformer_data == nil then
		return
	end
	-- log ('update_vehicle_transformer  --- post nil check.')
	local dt = tickdelay / 60
	
	for grid_draw_id, transformer_data_values in pairs(global.transformer_data) do
		local grid_draw_value = transformer_data_values.grid_draw
		-- log ('update_vehicle_transformer --- transformer_data_values: ' .. serpent.block(transformer_data_values))
		local grid = global.grid_vehicles[grid_draw_id].grid
		local vehicle_position = global.grid_vehicles[grid_draw_id].position
		-- if in appropriate position ie, in pole area
			-- do the thing
		-- else destroy invisible transformer entities
		local buffer = grid_draw_value / 10
		
		local grid_entities = transformer_data_values.grid_transformer_entities
		local avail_in = 0
		local request_out = 0
		for _, entity in pairs(grid_entities) do
			entity.teleport(vehicle_position)
			
			avail_in = avail_in + entity.energy
			request_out = request_out + (buffer - entity.energy)
		end

		-- log ('update_vehicle_transformer --- avail_in: ' .. serpent.block(avail_in))

		local max_draw = grid_draw_value

		
		local max_draw_in = global.transformer_data[grid_draw_id].equipment_draw_in
		local max_draw_out = global.transformer_data[grid_draw_id].equipment_draw_out
		-- max_draw_out = 0
		-- log ('update_vehicle_transformer --- max_draw_in: ' .. serpent.block(max_draw_in))
		
		local transformer_count = 1

		-- log ('update_vehicle_transformer --- pre check')
		-- log ('update_vehicle_transformer --- avail_in: ' .. serpent.block(avail_in))
		-- log ('update_vehicle_transformer --- request_out: ' .. serpent.block(request_out))
		-- log ('update_vehicle_transformer --- post check')
		-- log ('------------------------------------------')

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
		
		-- log ('update_vehicle_transformer --- pre label')

		-- log ('update_vehicle_transformer --- max_draw_in: ' .. serpent.block(max_draw_in))
		-- log ('update_vehicle_transformer --- max_draw_out: ' .. serpent.block(max_draw_out))

		-- log ('update_vehicle_transformer --- drain_in: ' .. serpent.block(drain_in))
		-- log ('update_vehicle_transformer --- drain_out: ' .. serpent.block(drain_out))

		-- log ('update_vehicle_transformer --- avail_in: ' .. serpent.block(avail_in))
		-- log ('update_vehicle_transformer --- request_out: ' .. serpent.block(request_out))
		-- log ('update_vehicle_transformer --- ratio_in: ' .. serpent.block(ratio_in))
		-- log ('update_vehicle_transformer --- ratio_out: ' .. serpent.block(ratio_out))
		
		-- log ('update_vehicle_transformer --- post label')
		-- log ('\n')
		
		-- for _, v in pairs(t.inputs) do
		for _, entity in pairs(grid_entities) do
			entity.energy = entity.energy * (1 - drain_in)
			entity.energy = buffer - ((buffer - entity.energy) * (1 - drain_out))
		end
		-- for _, v in pairs(t.outputs) do
--			grid_entity.energy = buffer - ((buffer - grid_entity.energy) * (1 - drain_out))
		-- end
		-- log ('energy_source in grid = '.. serpent.block(v.name))
		for _, v in pairs(grid.equipment) do
			if not is_personal_transformer_name_match(v.name) and v.prototype.energy_source ~= nil then
				-- log ('energy_source in grid = '.. serpent.block(v.name))

				-- v.energy = 100000000
				local draw_in = math.min(v.prototype.energy_source.input_flow_limit * tickdelay, v.prototype.energy_source.buffer_capacity - v.energy)
				local draw_out = math.min(v.prototype.energy_source.output_flow_limit * tickdelay, v.energy)
				local dE = draw_in * ratio_in - draw_out * ratio_out
				v.energy = v.energy + dE
			end
		end
		
	end
end

function add_grid_draw(equipment_name, grid_id, transformer_name, draw)
	if equipment_name == transformer_name then
		if global.transformer_data[grid_id].grid_draw then
			global.transformer_data[grid_id].grid_draw = global.transformer_data[grid_id].grid_draw + draw
		else
			global.transformer_data[grid_id].grid_draw = draw
		end
	end
end

function subtract_grid_draw(equipment_name, grid_id, transformer_name, draw)
	if equipment_name == transformer_name then
		if global.transformer_data[grid_id].grid_draw then
			global.transformer_data[grid_id].grid_draw = global.transformer_data[grid_id].grid_draw - draw
			if global.transformer_data[grid_id].grid_draw <= 0 then
				global.transformer_data[grid_id].grid_draw = nil
			end
		end
	end
end

function get_grid_energy_draw(grid)
	local max_draw_in = 0
	local max_draw_out = 0
	-- i might have to move this to the on_tick method....
	if global.transformer_data[grid.unique_id] then
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
		global.transformer_data[grid.unique_id].equipment_draw_in = max_draw_in
		global.transformer_data[grid.unique_id].equipment_draw_out = max_draw_out
	end
end

function is_personal_transformer_name_match(name)
	return name == personal_transformer_mk1_name or name == personal_transformer_mk2_name or name == personal_transformer_mk3_name
end

function insert_entity(equipment_name, grid_owner, grid_id)
	if is_personal_transformer_name_match(equipment_name) then
		local entity_input_name
		local entity_output_name
		if personal_transformer_mk1_name == equipment_name then
			entity_input_name = "personal-transformer-input-entity"
			entity_output_name = "personal-transformer-output-entity"
		elseif personal_transformer_mk2_name == equipment_name then
			entity_input_name = "personal-transformer-mk2-input-entity"
			entity_output_name = "personal-transformer-mk2-output-entity"
		elseif personal_transformer_mk3_name == equipment_name then
			entity_input_name = "personal-transformer-mk3-input-entity"
			entity_output_name = "personal-transformer-mk3-output-entity"
		end
		local input_entity = grid_owner.surface.create_entity
			{
				name = entity_input_name,
				position = grid_owner.position,
				force = grid_owner.force
			}
		table.insert(global.transformer_data[grid_id].grid_transformer_entities, input_entity)
		local output_entity = grid_owner.surface.create_entity
			{
				name = entity_output_name,
				position = grid_owner.position,
				force = grid_owner.force
			}
		table.insert(global.transformer_data[grid_id].grid_transformer_entities, output_entity)
	end
end

function remove_entity(equipment_name, grid_id)
	if is_personal_transformer_name_match(equipment_name) then
		local entity_input_name
		local entity_output_name
		if personal_transformer_mk1_name == equipment_name then
			entity_input_name = "personal-transformer-input-entity"
			entity_output_name = "personal-transformer-output-entity"
		elseif personal_transformer_mk2_name == equipment_name then
			entity_input_name = "personal-transformer-mk2-input-entity"
			entity_output_name = "personal-transformer-mk2-output-entity"
		elseif personal_transformer_mk3_name == equipment_name then
			entity_input_name = "personal-transformer-mk3-input-entity"
			entity_output_name = "personal-transformer-mk3-output-entity"
		end

		local input_check = false
		local output_check = false
		for index, entity in ipairs (global.transformer_data[grid_id].grid_transformer_entities) do 
			if (entity.name == entity_input_name) then
				local entity = table.remove(global.transformer_data[grid_id].grid_transformer_entities, index)
				log ('remove_entity --- entity: ' .. serpent.block(entity))
				entity.destroy()
				entity = nil
				input_check = true
			elseif (entity.name == entity_output_name) then
				local entity = table.remove(global.transformer_data[grid_id].grid_transformer_entities, index)
				log ('remove_entity --- entity: ' .. serpent.block(entity))
				entity.destroy()
				entity = nil
				output_check = true
			end
			if input_check and output_check then
				return
			end
		end
	end
end

function new_vehicle_placed_event_wrapper(event)
	new_vehicle_placed(event.created_entity)
end

function new_vehicle_placed(entity)
	if not isVehicleGridAllowed then
		return
	end
	-- add placed vehicle to vehicle list
	-- add draw total to draw list
--	log ('new_vehicle_placed start --- global.grid_vehicles = '.. serpent.block(global.grid_vehicles))
--	log ('new_vehicle_placed start --- created_entity.type = '.. serpent.block(entity.type))
	-- local vehicle = event.created_entity
	local vehicle = entity
	local grid = vehicle.grid
--	log ('new_vehicle_placed --- vehicle = '.. serpent.block(vehicle))
--	log ('new_vehicle_placed --- grid = '.. serpent.block(grid))
	if grid and grid.valid then
		local grid_id = grid.unique_id
		global.grid_vehicles[grid_id] = vehicle
		local mk1_count = grid.count(personal_transformer_mk1_name)
		local mk2_count = grid.count(personal_transformer_mk2_name)
		local mk3_count = grid.count(personal_transformer_mk3_name)
		local draw_total = (mk1_count * mk1_draw) + (mk2_count * mk2_draw) + (mk3_count * mk3_draw)
		if draw_total > 0 then
			if not global.transformer_data[grid_id] then 
				global.transformer_data[grid_id] = {}
				global.transformer_data[grid_id].grid_transformer_entities = {}
			end

			global.transformer_data[grid_id].grid_draw = draw_total

			if mk1_count > 0 then
				for i = 1, mk1_count do
					insert_entity(personal_transformer_mk1_name, vehicle, grid_id)
				end
			end
			if mk2_count > 0 then
				for i = 1, mk2_count do
					insert_entity(personal_transformer_mk2_name, vehicle, grid_id)
				end
			end
			if mk3_count > 0 then
				for i = 1, mk3_count do
					insert_entity(personal_transformer_mk3_name, vehicle, grid_id)
				end
			end
	
			get_grid_energy_draw(grid)
		end
	end
--	log ('new_vehicle_placed end --- global.transformer_data: ' .. serpent.block(global.transformer_data))
--	log ('new_vehicle_placed end --- global.grid_vehicles: ' .. serpent.block(global.grid_vehicles))
end

function entity_removed(entity)
--	log ('entity_removed start --- global.transformer_data: ' .. serpent.block(global.transformer_data))
--	log ('entity_removed start --- global.grid_vehicles: ' .. serpent.block(global.grid_vehicles))	
	local grid_id
	if not isVehicleGridAllowed then
		return
	end
	for index, vehicle_entity in pairs (global.grid_vehicles) do 
		if entity.unit_number == vehicle_entity.unit_number then
			grid_id = index
			global.grid_vehicles[grid_id] = nil
			global.transformer_data[grid_id] = nil
			break
		end
	end
--	log ('entity_removed end --- global.transformer_data: ' .. serpent.block(global.transformer_data))
--	log ('entity_removed end --- global.grid_vehicles: ' .. serpent.block(global.grid_vehicles))
end

function removeInputOutputTransformerEntities(playerIndex, old_surface_index, char_table)
	local t = char_table[playerIndex]
	if t == nil then
		return
	end
	-- if character suface is not the old surface, ie if character changed surfaces
	if t.surface_index ~= old_surface_index then
--		log ('RemoveI/O Transformer Entities. ')
--		log ('Player: ' .. serpent.block(t))
--		log ('Player Inputs: ' .. serpent.block(t.inputs))
--		log ('Table to Remove Inputs: ' .. serpent.block(char_table[playerIndex].inputs))
--		log ('Table to Remove Inputs Size: ' .. serpent.block(#t.inputs))
		char_table[playerIndex] = nil
		count = #t.inputs
		for i = 0, count do 
			if t.inputs[i] ~= nil then
				t.inputs[i].destroy()
			end
		end

		count = #t.outputs
		for i = 0, count do
			if t.outputs[i] ~= nil then
				t.outputs[i].destroy()
			end
		end
	end
end

function isPlayerOwnerOfGrid(grid_id)
	for _, p in pairs(game.players) do
		if p.character ~= nil then
			local grid = p.character.grid
			if grid.unique_id == grid_id then
				return p
			end
		end
	end
	return nil
end

function teleportEntitiesToPlayerPosition(player_pos, grid_transformer_entities)
-- NOTE: teleport across surfaces only works for players, cars, and spidertrons
	for _, pt_entity in pairs(grid_transformer_entities) do
		if pt_entity.position ~= player_pos then
			pt_entity.teleport(player_pos)
		end
	end
end

function equipmentInserted(player, grid_id, equipment_name)
	if is_personal_transformer_name_match(equipment_name) then
		if not global.transformer_data[grid_id] then 
			global.transformer_data[grid_id] = {}
			global.transformer_data[grid_id].grid_transformer_entities = {}
		end
		insert_entity(equipment_name, player, grid_id)

		if not global.transformer_data[grid_id].transformer_count then 
			global.transformer_data[grid_id].transformer_count = {}
			global.transformer_data[grid_id].transformer_count[personal_transformer_mk1_name] = 0
			global.transformer_data[grid_id].transformer_count[personal_transformer_mk2_name] = 0
			global.transformer_data[grid_id].transformer_count[personal_transformer_mk3_name] = 0
		end
log ('on_inserted equipment --- global.transformer_data: ' .. serpent.block(global.transformer_data))
		global.transformer_data[grid_id].transformer_count[equipment_name] = global.transformer_data[grid_id].transformer_count[equipment_name] + 1

		global.transformer_data[grid_id].grid_owner_id = player.index
		global.transformer_data[grid_id].grid_owner_type = "player"
		
		if global.transformer_data[grid_id].max_grid_draw == nil then
			global.transformer_data[grid_id].max_grid_draw = 0
		end
		global.transformer_data[grid_id].max_grid_draw = global.transformer_data[grid_id].max_grid_draw + transformer_draw[equipment_name]
		global.transformer_data[grid_id].buffer = global.transformer_data[grid_id].max_grid_draw / 10
log ('on_inserted equipment --- global.transformer_data after: ' .. serpent.block(global.transformer_data))
	end
end

function equipmentRemoved(grid_id, equipment_name, count)
	if is_personal_transformer_name_match(equipment_name) then
		for i = 0, count do 
			remove_entity(equipment_name, grid_id)
		end
		log ('on_equipment_removed  --- global.transformer_data: ' .. serpent.block(global.transformer_data))
		log ('on_equipment_removed --- global.transformer_data.transformer_count[array]: ' .. serpent.block(global.transformer_data[grid_id].transformer_count[personal_transformer_mk3_name]))
		global.transformer_data[grid_id].transformer_count[equipment_name] = global.transformer_data[grid_id].transformer_count[equipment_name] - count
		log ('on_equipment_removed post remove entity --- global.transformer_data after: ' .. serpent.block(global.transformer_data))
		global.transformer_data[grid_id].max_grid_draw = global.transformer_data[grid_id].max_grid_draw - (transformer_draw[equipment_name] * count)
		global.transformer_data[grid_id].buffer = global.transformer_data[grid_id].max_grid_draw / 10

		local total_count = global.transformer_data[grid_id].transformer_count[personal_transformer_mk1_name] + global.transformer_data[grid_id].transformer_count[personal_transformer_mk2_name] + global.transformer_data[grid_id].transformer_count[personal_transformer_mk3_name]

		if total_count == 0 then
			log ('If no more transformers --- Clear out object')
			global.transformer_data[grid_id].transformer_count = nil
			global.transformer_data[grid_id].grid_owner_id = nil
			global.transformer_data[grid_id].grid_owner_type = nil
			global.transformer_data[grid_id].max_grid_draw = nil
			global.transformer_data[grid_id].buffer = nil
			global.transformer_data[grid_id] = nil
		end
	end
end


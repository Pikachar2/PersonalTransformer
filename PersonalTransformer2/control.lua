local char_armor_transformers = nil
local vehicle_armor_transformers = nil
local my_types = {"car", "spider-vehicle", "rolling-stock"}

local tickdelay = 1

local mk1_draw = 200000
local mk2_draw = 1000000
local mk3_draw = 4000000

local personal_transformer_mk1_name = "personal-transformer-equipment"
local personal_transformer_mk2_name = "personal-transformer-mk2-equipment"
local personal_transformer_mk3_name = "personal-transformer-mk3-equipment"

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


script.on_init(
	function()
		char_armor_transformers = { }
		char_armor_transformers.trans = { }
		char_armor_transformers.trans2 = { }
		char_armor_transformers.trans3 = { }
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
		if char_armor_transformers.trans == nil then
			char_armor_transformers.trans = { }
			char_armor_transformers.trans2 = { }
			char_armor_transformers.trans3 = { }
		end
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
		local grid_id = event.grid.unique_id
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
		local grid_id = event.grid.unique_id
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
		log ('on_player_mined_entity start --- ')
		entity_removed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_robot_mined_entity, 
	function(event)
		log ('on_robot_mined_entity start --- ')
		entity_removed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_entity_destroyed, 
	function(event)
		-- entity_removed(event.entity)
	log ('on_entity_destroyed --- ')
	end

	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
)

script.on_event(defines.events.on_entity_died, 
	function(event)
		log ('on_entity_died start --- ')
		entity_removed(event.entity)
		log ('on_entity_died end --- ')
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
		
		if event.tick % tickdelay ~= 0 then
			return
		end
		update_personal_transformer(tickdelay, char_armor_transformers.trans, 'personal-transformer-equipment', 'personal-transformer-input-entity', 'personal-transformer-output-entity', mk1_draw)
		update_personal_transformer(tickdelay, char_armor_transformers.trans2, 'personal-transformer-mk2-equipment', 'personal-transformer-mk2-input-entity', 'personal-transformer-mk2-output-entity', mk2_draw)
		update_personal_transformer(tickdelay, char_armor_transformers.trans3, 'personal-transformer-mk3-equipment', 'personal-transformer-mk3-input-entity', 'personal-transformer-mk3-output-entity', mk3_draw)

		update_vehicle_transformer()

	end)

function update_personal_transformer(tickdelay, char_table, equip_name, input_name, output_name, max_draw)
	local dt = tickdelay / 60
	local buffer = max_draw / 10
	local _, p, t, v, grid = nil
	for _, p in pairs(game.players) do
	-- p is player
	-- t is character_armor_transformers
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
			log ('Creating new PT entities.')
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
--NOTE: The crash only occurs when there are multiple PTs in the armor.
-- The crash always occurs on the first v.energy reference after the surface switch
-- NOTE: I might not be clearing out the old ones correctly in the case of multiple
			log ('BEFORE loop crash- _: ' .. serpent.block(t.inputs))
					for _, v in pairs(t.inputs) do
			log ('In loop crash- _: ' .. serpent.block(_))
			log ('In loop crash- v: ' .. serpent.block(v))
			log ('In loop crash- drain_in: ' .. serpent.block(drain_in))
						if v.energy == nil then
			log ('In loop crash- v.energy is nill')
						end
						v.energy = 0
			log ('In loop crash- v.energy is NOT nill')
			log ('In loop crash- v.energy: ' .. serpent.block(v.energy))
			
						v.energy = v.energy * (1 - drain_in)
			log ('In loop crash- post calculation: ')
					end
			log ('AFTER loop crash- _: ' .. serpent.block(t.inputs))
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

function insert_entity(equipment_name, vehicle, grid_id)
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
		local input_entity = vehicle.surface.create_entity
			{
				name = entity_input_name,
				position = vehicle.position,
				force = vehicle.force
			}
		table.insert(global.transformer_data[grid_id].grid_transformer_entities, input_entity)
		local output_entity = vehicle.surface.create_entity
			{
				name = entity_output_name,
				position = vehicle.position,
				force = vehicle.force
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
		for _, t_inputs in ipairs(t.inputs) do
			removeInputOutputEntities(char_table[playerIndex].inputs, _)
		end
		for _, t_outputs in ipairs(t.outputs) do
			removeInputOutputEntities(char_table[playerIndex].outputs, _)
		end
	end
end

function removeInputOutputEntities(tableToRemoveFrom, index)
	local entity = table.remove(tableToRemoveFrom, index)
	log ('remove_entity --- entity: ' .. serpent.block(entity))
	entity.destroy()
	entity = nil
end

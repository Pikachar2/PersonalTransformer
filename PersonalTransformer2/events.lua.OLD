require("personal-transformer")

local vehicle_event_filters = {
	{filter = "type", type = "car"},
	{filter = "type", type = "spider-vehicle"},
	{filter = "type", type = "locomotive"},
	{filter = "type", type = "cargo-wagon"},
	{filter = "type", type = "fluid-wagon"},
	{filter = "type", type = "artillery-wagon"}
}

local pt_entity_event_filters = {
	{filter = "name", name = "personal-transformer-input-entity"},
	{filter = "name", name = "personal-transformer-output-entity"},
	{filter = "name", name = "personal-transformer-mk2-input-entity"},
	{filter = "name", name = "personal-transformer-mk2-output-entity"},
	{filter = "name", name = "personal-transformer-mk3-input-entity"},
	{filter = "name", name = "personal-transformer-mk3-output-entity"}
}

-- local is_quality_enabled = script.active_mods["quality"]

script.on_event(defines.events.on_equipment_inserted,
	function(event)
-- CHARACTER CODE
--		log ('on_equipment_inserted start --- ')
		local grid_id = event.grid.unique_id
		local player = isPlayerOwnerOfGrid(grid_id)
		
		if player ~= nil then
--log ('on_equipment_inserted --- event.equipment.quality.name = '.. serpent.block(event.equipment.quality.name))
			equipmentInserted(player, grid_id, event.equipment.name, "player", event.equipment.quality.name)
			return
		end

-- VEHICLE CODE
		if not isVehicleGridAllowed then
			return
		end
--log ('on_equipment_inserted vehicle grids allowed --- ')
		local valid_vehicle = storage.grid_vehicles[grid_id] -- and storage.grid_vehicles[grid_id].entity
--log ('on_equipment_inserted vehicle grid_id --- ' .. serpent.block(grid_id))
--log ('on_equipment_inserted grid_vehicles --- ' .. serpent.block(storage.grid_vehicles))
--log ('on_equipment_inserted vehicle --- ' .. serpent.block(valid_vehicle))
		if valid_vehicle and valid_vehicle.valid then
--log ('on_equipment_inserted valid vehicle --- ')
			equipmentInserted(valid_vehicle, grid_id, event.equipment.name, "entity", event.equipment.quality.name)
		end
	end
)

script.on_event(defines.events.on_equipment_removed,
	function(event)
--		log ('on_equipment_removed start --- ')
		local grid_id = event.grid.unique_id
		if storage.transformer_data[grid_id] == nil then
			return
		end

		if storage.transformer_data[grid_id].grid_owner_type == "player" or storage.transformer_data[grid_id].grid_owner_type == nil then
			equipmentRemoved(grid_id, event.equipment, event.count, event.quality)
			return
		end
	
	-- VEHICLE CODE
		if not isVehicleGridAllowed then
			return
		end
		local valid_vehicle =  storage.grid_vehicles[grid_id] -- and storage.grid_vehicles[grid_id].entity
		
		if valid_vehicle and valid_vehicle.valid then
			if storage.transformer_data[grid_id].grid_owner_type == "entity" or storage.transformer_data[grid_id].grid_owner_type == nil then
				equipmentRemoved(grid_id, event.equipment, event.count, event.quality)
				return
			end
		end
--		log ('on_removed end --- storage.transformer_data: ' .. serpent.block(storage.transformer_data))
	end
)

script.on_event(defines.events.on_player_armor_inventory_changed, 
	function(event)
--log ('on_player_armor_inventory_changed --- storage.transformer_data: ' .. serpent.block(storage.transformer_data))
		playerOrArmorChanged(event.player_index)
	end
)

script.on_event(defines.events.on_built_entity, 
	function(event)
--log ('on_built_entity --- ')
--log ('on_built_entity entity type --- '.. serpent.block(event.created_entity.type))
		new_vehicle_placed_event_wrapper(event)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
, vehicle_event_filters
)

script.on_event(defines.events.on_robot_built_entity, 
	function(event)
--log ('on_robot_built_entity --- ')
		new_vehicle_placed_event_wrapper(event)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
, vehicle_event_filters
)

script.on_event(defines.events.on_entity_cloned, 
	function(event)
--		log ('on_entity_cloned start --- ')
		new_vehicle_placed(event.destination)
		purgeOrphanedEntities()		
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
, vehicle_event_filters
)

script.on_event(defines.events.script_raised_built, 
	function(event)
--log ('script_raised_built --- ')
		new_vehicle_placed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
, vehicle_event_filters
)

script.on_event(defines.events.script_raised_revive, 
	function(event)
--log ('script_raised_revive --- ')
		new_vehicle_placed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
, vehicle_event_filters
)

script.on_event(defines.events.on_player_mined_entity, 
	function(event)
--		log ('on_player_mined_entity start --- ')
		entity_removed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
, vehicle_event_filters
)

script.on_event(defines.events.on_robot_mined_entity, 
	function(event)
--		log ('on_robot_mined_entity start --- ')
		entity_removed(event.entity)
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
, vehicle_event_filters
)

script.on_event(defines.events.on_object_destroyed, 
	function(event)
		-- entity_removed(event.entity)
--	log ('on_entity_destroyed --- ')
	end
)

script.on_event(defines.events.on_entity_died, 
	function(event)
--		log ('on_entity_died start --- ')
		entity_removed(event.entity)
--		log ('on_entity_died end --- ')
	end

	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
, vehicle_event_filters
)

script.on_event(defines.events.script_raised_destroy, 
	function(event)
--		log ('script_raised_destroy start --- ')
		entity_removed(event.entity)
--		log ('script_raised_destroy end --- ')
	end
	-- {LuaPlayerBuiltEntityEventFilters = {"vehicle"}} -- incorrect way
	-- ,{{filter = "name", name = "vehicle"}}
, vehicle_event_filters
)

script.on_event(defines.events.on_player_changed_surface, 
	function(event)
		log ('on_player_changed_surface start --- ')
	-- Need to remove entities and re-add them on new surface
	-- Might want to only do this if character leaves surface, not player
		playerOrArmorChanged(event.player_index)
	end
)

script.on_event(defines.events.on_pre_player_died, 
	function(event)
--		log ('on_pre_player_died start --- ')
		playerOrArmorChanged(event.player_index)
--		log ('on_pre_player_died end --- ')
	end
)

script.on_event(defines.events.script_raised_teleported, 
	function(event)
--		log ('script_raised_teleported start --- ')
		entityTeleported(event.entity)
--		log ('script_raised_teleported end --- ')
	end
, vehicle_event_filters
)

script.on_event(defines.events.on_player_driving_changed_state, 
	function(event)
--		log ('on_player_driving_changed_state start --- ')
--		listCurrentAndAllPTEntities()
	end
)

script.on_event(defines.events.on_player_cheat_mode_enabled, 
	function(event)
--		log ('on_player_cheat_mode_enabled start --- ')
	end
)

script.on_event(defines.events.on_lua_shortcut,
	function(event)
--log ('on_player_driving_changed_state start --- ')
		if event.prototype_name == 'toggle-equipment-transformer-input' or event.prototype_name == 'toggle-equipment-transformer-output' then
			local player = game.players[event.player_index]
			if event.prototype_name == 'toggle-equipment-transformer-input' then
				player.set_shortcut_toggled('toggle-equipment-transformer-input', not player.is_shortcut_toggled('toggle-equipment-transformer-input'))
			elseif event.prototype_name == 'toggle-equipment-transformer-output' then
				player.set_shortcut_toggled('toggle-equipment-transformer-output', not player.is_shortcut_toggled('toggle-equipment-transformer-output'))
			end
		end
	end
)

script.on_event(defines.events.on_tick,
	function(event)
		tickdelay = settings.global["personal-transformer2-tick-delay"].value

		if event.tick % tickdelay ~= 0 then
			return
		end
		update_personal_transformer(tickdelay, storage.transformer_data)

		update_vehicle_transformer(tickdelay, storage.transformer_data)

	end)

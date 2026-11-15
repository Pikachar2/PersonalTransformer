local tick_delay = settings.global["personal-transformer2-tick-delay"].value

local vehicle_event_filters = {}
for _, type_name in ipairs(PT.VEHICLE_TYPE_LIST) do
	table.insert(vehicle_event_filters, {filter = "type", type = type_name})
end

local combined_filters = {}
for _, f in ipairs(vehicle_event_filters) do
	table.insert(combined_filters, f)
end
for _, entity_name in ipairs(PT.ENTITY_NAME_LIST) do
	table.insert(combined_filters, {filter = "name", name = entity_name})
end

-- Lifecycle & settings events
script.on_init(PT.init_storage)

script.on_configuration_changed(function()
	PT.init_storage()
	storage.grid_vehicles = {}

	if not PT.is_vehicle_grid_allowed then return end

	for _, surface in pairs(game.surfaces) do
		for _, vehicle in pairs(surface.find_entities_filtered{type = PT.VEHICLE_TYPE_LIST}) do
			if vehicle.valid and vehicle.grid and vehicle.grid.valid then
				storage.grid_vehicles[vehicle.grid.unique_id] = vehicle
			end
		end
	end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting == "personal-transformer2-tick-delay" then
		tick_delay = settings.global["personal-transformer2-tick-delay"].value
	end
end)

-- Equipment grid events
script.on_event(defines.events.on_equipment_inserted, function(event)
	local grid_id = event.grid.unique_id
	local player = PT.get_player_for_grid(grid_id)

	if player then
		PT.equipment_inserted(player, grid_id, event.equipment.name, "player", event.equipment.quality.name)
		return
	end

	if not PT.is_vehicle_grid_allowed then return end

	local vehicle = storage.grid_vehicles[grid_id]
	if vehicle and vehicle.valid then
		PT.equipment_inserted(vehicle, grid_id, event.equipment.name, "entity", event.equipment.quality.name)
	end
end)

script.on_event(defines.events.on_equipment_removed, function(event)
	local grid_id = event.grid.unique_id
	local data = storage.transformer_data[grid_id]
	if not data then return end

	if data.grid_owner_type == "player" or data.grid_owner_type == nil then
		PT.equipment_removed(grid_id, event.equipment, event.count, event.quality)
		return
	end

	if not PT.is_vehicle_grid_allowed then return end

	local vehicle = storage.grid_vehicles[grid_id]
	if vehicle and vehicle.valid and (data.grid_owner_type == "entity" or data.grid_owner_type == nil) then
		PT.equipment_removed(grid_id, event.equipment, event.count, event.quality)
	end
end)

-- Player state events
script.on_event(defines.events.on_player_armor_inventory_changed, function(event)
	PT.player_or_armor_changed(event.player_index)
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
	PT.player_or_armor_changed(event.player_index)
end)

script.on_event(defines.events.on_pre_player_died, function(event)
	PT.player_or_armor_changed(event.player_index)
end)

-- Vehicle build & revive events
script.on_event(defines.events.on_built_entity, function(event)
	PT.new_vehicle_placed(event.entity)
end, vehicle_event_filters)

script.on_event(defines.events.on_robot_built_entity, function(event)
	PT.new_vehicle_placed(event.entity)
end, vehicle_event_filters)

script.on_event(defines.events.script_raised_built, function(event)
	PT.new_vehicle_placed(event.entity)
end, vehicle_event_filters)

script.on_event(defines.events.script_raised_revive, function(event)
	PT.new_vehicle_placed(event.entity)
end, vehicle_event_filters)

-- Vehicle removal & destruction events
script.on_event(defines.events.on_player_mined_entity, function(event)
	PT.entity_removed(event.entity)
end, vehicle_event_filters)

script.on_event(defines.events.on_robot_mined_entity, function(event)
	PT.entity_removed(event.entity)
end, vehicle_event_filters)

script.on_event(defines.events.on_entity_died, function(event)
	PT.entity_removed(event.entity)
end, vehicle_event_filters)

script.on_event(defines.events.script_raised_destroy, function(event)
	PT.entity_removed(event.entity)
end, vehicle_event_filters)

-- Cloning & teleportation events
script.on_event(defines.events.on_entity_cloned, function(event)
	if PT.VEHICLE_TYPES[event.source.type] then
		PT.new_vehicle_placed(event.destination)
		PT.purge_orphaned_entities()
	elseif PT.ENTITY_NAMES[event.source.name] then
		PT.pt_entity_cloned(event.source, event.destination)
	end
end, combined_filters)

script.on_event(defines.events.script_raised_teleported, function(event)
	PT.entity_teleported(event.entity)
end, vehicle_event_filters)

-- Shortcut & tick events
script.on_event(defines.events.on_lua_shortcut, function(event)
	if event.prototype_name == "toggle-equipment-transformer-input" or event.prototype_name == "toggle-equipment-transformer-output" then
		local player = game.players[event.player_index]
		if player and player.valid then
			player.set_shortcut_toggled(event.prototype_name, not player.is_shortcut_toggled(event.prototype_name))
		end
	end
end)

script.on_event(defines.events.on_tick, function(event)
	if event.tick % tick_delay == 0 then
		PT.update_transformers(tick_delay)
	end
end)

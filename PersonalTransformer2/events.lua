local current_tick_delay = settings.global["personal-transformer2-tick-delay"].value
local is_tick_registered = false

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

local function on_nth_tick_update()
	PT.update_transformers(current_tick_delay)
end

function PT.sync_tick_registration()
	local has_active = next(storage.transformer_data) ~= nil
	if has_active and not is_tick_registered then
		script.on_nth_tick(current_tick_delay, on_nth_tick_update)
		is_tick_registered = true
	elseif not has_active and is_tick_registered then
		script.on_nth_tick(current_tick_delay, nil)
		is_tick_registered = false
	end
end

-- Lifecycle & settings events
script.on_init(function()
	PT.init_storage()
	PT.sync_tick_registration()
end)

script.on_load(function()
	PT.sync_tick_registration()
end)

script.on_configuration_changed(function()
	PT.migrate_and_rebuild_all()
	PT.sync_tick_registration()
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting == "personal-transformer2-tick-delay" then
		if is_tick_registered then
			script.on_nth_tick(current_tick_delay, nil)
		end
		current_tick_delay = settings.global["personal-transformer2-tick-delay"].value
		if is_tick_registered then
			script.on_nth_tick(current_tick_delay, on_nth_tick_update)
		end
	end
end)

-- Equipment grid events
script.on_event(defines.events.on_equipment_inserted, function(event)
	local grid = event.grid
	local grid_id = grid.unique_id
	local player = PT.get_player_for_grid(grid_id)

	if player then
		PT.equipment_inserted(player, grid_id, event.equipment.name, "player", event.equipment.quality.name)
		PT.refresh_grid_composition(grid, grid_id)
		PT.sync_tick_registration()
		return
	end

	if not PT.is_vehicle_grid_allowed then return end

	local vehicle = storage.grid_vehicles[grid_id]
	if vehicle and vehicle.valid then
		PT.equipment_inserted(vehicle, grid_id, event.equipment.name, "entity", event.equipment.quality.name)
		PT.refresh_grid_composition(grid, grid_id)
		PT.sync_tick_registration()
	end
end)

script.on_event(defines.events.on_equipment_removed, function(event)
	local grid = event.grid
	local grid_id = grid.unique_id
	local data = storage.transformer_data[grid_id]
	if not data then return end

	if data.grid_owner_type == "player" or data.grid_owner_type == nil then
		PT.equipment_removed(grid_id, event.equipment, event.count, event.quality)
		PT.refresh_grid_composition(grid, grid_id)
		PT.sync_tick_registration()
		return
	end

	if not PT.is_vehicle_grid_allowed then return end

	local vehicle = storage.grid_vehicles[grid_id]
	if vehicle and vehicle.valid and (data.grid_owner_type == "entity" or data.grid_owner_type == nil) then
		PT.equipment_removed(grid_id, event.equipment, event.count, event.quality)
		PT.refresh_grid_composition(grid, grid_id)
		PT.sync_tick_registration()
	end
end)

-- Player state & Space Exploration controller/cutscene events
script.on_event(defines.events.on_player_armor_inventory_changed, function(event)
	PT.player_or_armor_changed(event.player_index)
	PT.sync_tick_registration()
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
	PT.player_or_armor_changed(event.player_index)
	PT.purge_orphaned_entities()
	PT.sync_tick_registration()
end)

script.on_event(defines.events.on_player_controller_changed, function(event)
	PT.player_or_armor_changed(event.player_index)
	PT.sync_tick_registration()
end)

script.on_event(defines.events.on_cutscene_cancelled, function(event)
	PT.player_or_armor_changed(event.player_index)
	PT.sync_tick_registration()
end)

script.on_event(defines.events.on_pre_player_died, function(event)
	PT.clear_player_transformers(event.player_index)
	PT.sync_tick_registration()
end)

script.on_event(defines.events.on_player_respawned, function(event)
	PT.player_or_armor_changed(event.player_index)
	PT.sync_tick_registration()
end)

-- Vehicle build & revive events
script.on_event(defines.events.on_built_entity, function(event)
	PT.new_vehicle_placed(event.entity)
	PT.sync_tick_registration()
end, vehicle_event_filters)

script.on_event(defines.events.on_robot_built_entity, function(event)
	PT.new_vehicle_placed(event.entity)
	PT.sync_tick_registration()
end, vehicle_event_filters)

script.on_event(defines.events.script_raised_built, function(event)
	PT.new_vehicle_placed(event.entity)
	PT.sync_tick_registration()
end, vehicle_event_filters)

script.on_event(defines.events.script_raised_revive, function(event)
	PT.new_vehicle_placed(event.entity)
	PT.sync_tick_registration()
end, vehicle_event_filters)

-- Vehicle removal & destruction events
script.on_event(defines.events.on_player_mined_entity, function(event)
	PT.entity_removed(event.entity)
	PT.sync_tick_registration()
end, vehicle_event_filters)

script.on_event(defines.events.on_robot_mined_entity, function(event)
	PT.entity_removed(event.entity)
	PT.sync_tick_registration()
end, vehicle_event_filters)

script.on_event(defines.events.on_entity_died, function(event)
	PT.entity_removed(event.entity)
	PT.sync_tick_registration()
end, vehicle_event_filters)

script.on_event(defines.events.script_raised_destroy, function(event)
	PT.entity_removed(event.entity)
	PT.sync_tick_registration()
end, vehicle_event_filters)

script.on_event(defines.events.on_object_destroyed, function(event)
	PT.on_object_destroyed(event.registration_number)
	PT.sync_tick_registration()
end)

-- Cloning & teleportation events
script.on_event(defines.events.on_entity_cloned, function(event)
	if PT.VEHICLE_TYPES[event.source.type] then
		PT.new_vehicle_placed(event.destination)
		PT.sync_tick_registration()
	elseif PT.ENTITY_NAMES[event.source.name] then
		if event.destination and event.destination.valid then
			event.destination.destroy()
		end
	end
end, combined_filters)

script.on_event(defines.events.script_raised_teleported, function(event)
	PT.entity_teleported(event.entity)
	PT.sync_tick_registration()
end, vehicle_event_filters)

-- Shortcut & custom-input events
local function toggle_player_shortcut(player_index, shortcut_name)
	local player = game.players[player_index]
	if player and player.valid and player.is_shortcut_available(shortcut_name) then
		player.set_shortcut_toggled(shortcut_name, not player.is_shortcut_toggled(shortcut_name))
	end
end

script.on_event(defines.events.on_lua_shortcut, function(event)
	if event.prototype_name == "toggle-equipment-transformer-input" or event.prototype_name == "toggle-equipment-transformer-output" then
		toggle_player_shortcut(event.player_index, event.prototype_name)
	end
end)

script.on_event("toggle-equipment-transformer-input", function(event)
	toggle_player_shortcut(event.player_index, "toggle-equipment-transformer-input")
end)

script.on_event("toggle-equipment-transformer-output", function(event)
	toggle_player_shortcut(event.player_index, "toggle-equipment-transformer-output")
end)

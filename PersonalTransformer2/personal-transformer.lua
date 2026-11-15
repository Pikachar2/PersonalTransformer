local min = math.min
local max = math.max
local pairs = pairs
local next = next
local REMOTE_CONTROLLER = defines.controllers.remote

PT.VEHICLE_TYPES = {
	["car"] = true,
	["spider-vehicle"] = true,
	["locomotive"] = true,
	["cargo-wagon"] = true,
	["fluid-wagon"] = true,
	["artillery-wagon"] = true
}

PT.VEHICLE_TYPE_LIST = {}
for type_name in pairs(PT.VEHICLE_TYPES) do
	table.insert(PT.VEHICLE_TYPE_LIST, type_name)
end

PT.is_vehicle_grid_allowed = settings.startup["personal-transformer2-allow-non-armor"].value

PT.TRANSFORMER_TIERS = {
	["personal-transformer-equipment"] = {
		in_draw = settings.startup["personal-transformer-mk1-flow-limit"].value * 1000,
		out_draw = settings.startup["personal-transformer-mk1-output-limit"].value * 1000,
		buffer = settings.startup["personal-transformer-mk1-buffer-capacity"].value * 1000
	},
	["personal-transformer-mk2-equipment"] = {
		in_draw = settings.startup["personal-transformer-mk2-flow-limit"].value * 1000,
		out_draw = settings.startup["personal-transformer-mk2-output-limit"].value * 1000,
		buffer = settings.startup["personal-transformer-mk2-buffer-capacity"].value * 1000
	},
	["personal-transformer-mk3-equipment"] = {
		in_draw = settings.startup["personal-transformer-mk3-flow-limit"].value * 1000,
		out_draw = settings.startup["personal-transformer-mk3-output-limit"].value * 1000,
		buffer = settings.startup["personal-transformer-mk3-buffer-capacity"].value * 1000
	}
}

PT.PROXY_INPUT_NAME = "personal-transformer-input-entity"
PT.PROXY_OUTPUT_NAME = "personal-transformer-output-entity"

PT.ENTITY_NAMES = {
	[PT.PROXY_INPUT_NAME] = true,
	[PT.PROXY_OUTPUT_NAME] = true,
	["personal-transformer-mk2-input-entity"] = true,
	["personal-transformer-mk2-output-entity"] = true,
	["personal-transformer-mk3-input-entity"] = true,
	["personal-transformer-mk3-output-entity"] = true
}

PT.ENTITY_NAME_LIST = {}
for name in pairs(PT.ENTITY_NAMES) do
	table.insert(PT.ENTITY_NAME_LIST, name)
end

function PT.init_storage()
	storage.transformer_data = storage.transformer_data or {}
	storage.grid_vehicles = storage.grid_vehicles or {}
	storage.destroyed_registrations = storage.destroyed_registrations or {}
end

local EQUIP_FLOW_CACHE = {}
local scratch_eq = {}
local scratch_in = {}
local scratch_out = {}

local ensure_and_sync_proxy_pair
local destroy_proxy_pair

local function get_quality_multiplier(quality_name)
	local q = quality_name and prototypes.quality[quality_name]
	return q and (1 + 0.3 * q.level) or 1
end

local function get_equipment_flow_info(eq)
	local name = eq.name
	local quality_name = eq.quality.name
	local by_name = EQUIP_FLOW_CACHE[name]
	if by_name then
		local cached = by_name[quality_name]
		if cached ~= nil then
			return cached
		end
	else
		by_name = {}
		EQUIP_FLOW_CACHE[name] = by_name
	end

	local proto = eq.prototype
	local es = proto.energy_source
	local info = false
	if es and es.valid then
		local ptype = proto.type
		local is_source = (ptype == "battery-equipment" or ptype == "generator-equipment")
		info = {
			in_limit = es.get_input_flow_limit(quality_name),
			out_limit = is_source and es.get_output_flow_limit(quality_name) or 0,
			max_energy = eq.max_energy,
			is_source = is_source
		}
	end

	by_name[quality_name] = info
	return info
end

local function teleport_proxy_pair_if_moved(data, target_pos, owner, owner_type)
	if owner_type == "player" and owner.controller_type == REMOTE_CONTROLLER then
		return
	end

	local in_ent = data.input_entity
	local out_ent = data.output_entity
	local owner_surface = owner.surface

	if (in_ent and in_ent.valid and in_ent.surface ~= owner_surface)
		or (out_ent and out_ent.valid and out_ent.surface ~= owner_surface) then
		destroy_proxy_pair(data)
		data.last_x = target_pos.x
		data.last_y = target_pos.y
		ensure_and_sync_proxy_pair(data, owner)
		return
	end

	local tx = target_pos.x
	local ty = target_pos.y
	if data.last_x == tx and data.last_y == ty then
		return
	end

	data.last_x = tx
	data.last_y = ty

	if in_ent and in_ent.valid then
		in_ent.teleport(target_pos)
	end

	if out_ent and out_ent.valid then
		out_ent.teleport(target_pos)
	end
end

local function process_grid_energy(grid, data, tickdelay, allow_in, allow_out)
	local in_ent = data.input_entity
	local out_ent = data.output_entity
	local buffer = data.buffer

	local avail_in = (allow_in and in_ent and in_ent.valid) and in_ent.energy or 0
	local request_out = (allow_out and out_ent and out_ent.valid) and (buffer - out_ent.energy) or 0

	if 0 >= avail_in and 0 >= request_out then
		return
	end

	local can_in = avail_in > 0
	local can_out = request_out > 0

	if can_in and not can_out then
		if (data.consumer_count or 0) == 0 and grid.available_in_batteries == grid.battery_capacity then
			return
		end
	elseif can_out and not can_in then
		if (data.generator_count or 0) == 0 and grid.available_in_batteries == 0 then
			return
		end
	end

	local max_draw_in = 0
	local max_draw_out = 0
	local count = 0

	for _, eq in pairs(grid.equipment) do
		local info = get_equipment_flow_info(eq)
		if info then
			local energy = eq.energy
			local d_in = 0
			local d_out = 0

			if can_in and info.in_limit > 0 then
				local room = info.max_energy - energy
				if room > 0 then
					local limit = info.in_limit * tickdelay
					d_in = (room > limit) and limit or room
					max_draw_in = max_draw_in + d_in
				end
			end

			if can_out and info.is_source and info.out_limit > 0 and energy > 0 then
				local limit = info.out_limit * tickdelay
				d_out = (energy > limit) and limit or energy
				max_draw_out = max_draw_out + d_out
			end

			if d_in > 0 or d_out > 0 then
				count = count + 1
				scratch_eq[count] = eq
				scratch_in[count] = d_in
				scratch_out[count] = d_out
			end
		end
	end

	if count == 0 then return end

	local dt = tickdelay / 60
	local max_step_in = (data.max_grid_in or data.max_grid_draw or 0) * dt
	local max_step_out = (data.max_grid_out or data.max_grid_draw or 0) * dt

	local actual_in = min(max_draw_in, avail_in, max_step_in)
	local actual_out = min(max_draw_out, request_out, max_step_out)

	local ratio_in = (max_draw_in > 0) and (actual_in / max_draw_in) or 0
	local ratio_out = (max_draw_out > 0) and (actual_out / max_draw_out) or 0

	if actual_in > 0 then
		in_ent.energy = max(avail_in - actual_in, 0)
	end

	if actual_out > 0 then
		out_ent.energy = min(out_ent.energy + actual_out, buffer)
	end

	if ratio_in > 0 or ratio_out > 0 then
		for i = 1, count do
			local eq = scratch_eq[i]
			eq.energy = eq.energy + (scratch_in[i] * ratio_in) - (scratch_out[i] * ratio_out)
			scratch_eq[i] = nil
		end
	else
		for i = 1, count do
			scratch_eq[i] = nil
		end
	end
end

function PT.update_transformers(tickdelay)
	if not next(storage.transformer_data) then return end

	for _, data in pairs(storage.transformer_data) do
		if data.grid_owner_type == "player" then
			local player = game.players[data.grid_owner_id]
			if player and player.valid and player.character and player.character.grid then
				teleport_proxy_pair_if_moved(data, player.position, player, "player")

				local allow_in = player.is_shortcut_toggled("toggle-equipment-transformer-input")
				local allow_out = player.is_shortcut_toggled("toggle-equipment-transformer-output")

				if allow_in or allow_out then
					process_grid_energy(player.character.grid, data, tickdelay, allow_in, allow_out)
				end
			end
		elseif PT.is_vehicle_grid_allowed and data.grid_owner_type == "entity" then
			local vehicle = storage.grid_vehicles[data.grid_owner_id]
			if vehicle and vehicle.valid and vehicle.grid then
				teleport_proxy_pair_if_moved(data, vehicle.position, vehicle, "entity")
				local allow_in = (data.allow_in ~= false)
				local allow_out = (data.allow_out == true)
				if allow_in or allow_out then
					process_grid_energy(vehicle.grid, data, tickdelay, allow_in, allow_out)
				end
			end
		end
	end
end

local function toggle_shortcut_available(player, is_available)
	if player and player.valid then
		player.set_shortcut_available("toggle-equipment-transformer-input", is_available)
		player.set_shortcut_available("toggle-equipment-transformer-output", is_available)
	end
end

ensure_and_sync_proxy_pair = function(data, owner)
	local surface = owner.surface
	if surface.name:find("^spaceship%-") then
		destroy_proxy_pair(data)
		return
	end

	local buffer = data.buffer
	local pos = owner.position
	local force = owner.force

	if not (data.input_entity and data.input_entity.valid) then
		data.input_entity = surface.create_entity{
			name = PT.PROXY_INPUT_NAME,
			position = pos,
			force = force
		}
	end
	if data.input_entity and data.input_entity.valid then
		data.input_entity.electric_buffer_size = buffer
	end

	if not (data.output_entity and data.output_entity.valid) then
		data.output_entity = surface.create_entity{
			name = PT.PROXY_OUTPUT_NAME,
			position = pos,
			force = force
		}
		if data.output_entity and data.output_entity.valid then
			data.output_entity.electric_buffer_size = buffer
			data.output_entity.energy = buffer
		end
	elseif data.output_entity and data.output_entity.valid then
		data.output_entity.electric_buffer_size = buffer
	end
end

destroy_proxy_pair = function(data)
	if data.input_entity and data.input_entity.valid then
		data.input_entity.destroy()
	end
	if data.output_entity and data.output_entity.valid then
		data.output_entity.destroy()
	end
	data.input_entity = nil
	data.output_entity = nil
end

function PT.refresh_grid_composition(grid, grid_id)
	local data = storage.transformer_data[grid_id]
	if not data or not (grid and grid.valid) then return end

	local generators = 0
	local consumers = 0

	for _, eq in pairs(grid.equipment) do
		local info = get_equipment_flow_info(eq)
		if info then
			local ptype = eq.prototype.type
			if ptype == "generator-equipment" then
				generators = generators + 1
			elseif ptype ~= "battery-equipment" and info.in_limit > 0 then
				consumers = consumers + 1
			end
		end
	end

	data.generator_count = generators
	data.consumer_count = consumers
end

local function get_vehicle_defaults(player_index)
	if player_index then
		local p_settings = settings.get_player_settings(player_index)
		if p_settings then
			return p_settings["personal-transformer2-default-vehicle-in"].value,
				p_settings["personal-transformer2-default-vehicle-out"].value
		end
	end
	return true, false
end

local RESEARCH_ENABLED = settings.startup["personal-transformer2-enable-research"].value
local RESEARCH_TECH_NAME = "personal-transformer-efficiency"
local RESEARCH_BONUS_TYPE = settings.startup["personal-transformer2-research-bonus-type"].value
local RESEARCH_BONUS_VALUE = settings.startup["personal-transformer2-research-bonus"].value

function PT.get_force_research_levels(force)
	if not RESEARCH_ENABLED or not (force and force.valid) then return 0 end
	local tech = force.technologies[RESEARCH_TECH_NAME]
	if not tech then return 0 end

	local completed_levels = (tech.level or 1) - 1
	if tech.researched then
		completed_levels = completed_levels + 1
	end
	return completed_levels
end

local function get_effective_tier_stats(tier, quality_name, force)
	local q_mult = get_quality_multiplier(quality_name)
	local levels = PT.get_force_research_levels(force)

	local item_in = tier.in_draw
	local item_out = tier.out_draw
	local item_buf = tier.buffer

	if levels > 0 then
		if RESEARCH_BONUS_TYPE == "flat" then
			local flat_watts = levels * RESEARCH_BONUS_VALUE * 1000
			item_in = item_in + flat_watts
			item_out = item_out + flat_watts
			item_buf = item_buf + (flat_watts * 0.1)
		else
			local pct_mult = 1 + (levels * (RESEARCH_BONUS_VALUE / 100))
			item_in = item_in * pct_mult
			item_out = item_out * pct_mult
			item_buf = item_buf * pct_mult
		end
	end

	return item_in * q_mult, item_out * q_mult, item_buf * q_mult
end

function PT.equipment_inserted(owner, grid_id, equipment_name, grid_owner_type, quality_name, player_index)
	local tier = PT.TRANSFORMER_TIERS[equipment_name]
	if not tier then return end

	local data = storage.transformer_data[grid_id]
	if not data then
		local def_in, def_out = get_vehicle_defaults(player_index)
		data = {
			transformer_count = 0,
			max_grid_in = 0,
			max_grid_out = 0,
			buffer = 0,
			allow_in = def_in,
			allow_out = def_out
		}
		storage.transformer_data[grid_id] = data
	end

	local eff_in, eff_out, eff_buf = get_effective_tier_stats(tier, quality_name, owner.force)
	data.transformer_count = (data.transformer_count or 0) + 1
	data.max_grid_in = (data.max_grid_in or 0) + eff_in
	data.max_grid_out = (data.max_grid_out or 0) + eff_out
	data.buffer = (data.buffer or 0) + eff_buf
	data.grid_owner_type = grid_owner_type

	if grid_owner_type == "player" then
		data.grid_owner_id = owner.index
		toggle_shortcut_available(owner, true)
	else
		data.grid_owner_id = grid_id
	end

	ensure_and_sync_proxy_pair(data, owner)
end

function PT.equipment_removed(grid_id, equipment_name, count, quality_name)
	local tier = PT.TRANSFORMER_TIERS[equipment_name]
	local data = storage.transformer_data[grid_id]
	if not tier or not data then
		return
	end

	local mult = get_quality_multiplier(quality_name) * count
	data.transformer_count = max((data.transformer_count or 0) - count, 0)
	data.max_grid_in = max((data.max_grid_in or 0) - (tier.in_draw * mult), 0)
	data.max_grid_out = max((data.max_grid_out or 0) - (tier.out_draw * mult), 0)
	data.buffer = max((data.buffer or 0) - (tier.buffer * mult), 0)

	if data.transformer_count == 0 or (0.001 > data.max_grid_in and 0.001 > data.max_grid_out) then
		if data.grid_owner_type == "player" then
			toggle_shortcut_available(game.players[data.grid_owner_id], false)
		end
		destroy_proxy_pair(data)
		storage.transformer_data[grid_id] = nil
	else
		if data.input_entity and data.input_entity.valid then
			data.input_entity.electric_buffer_size = data.buffer
		end
		if data.output_entity and data.output_entity.valid then
			data.output_entity.electric_buffer_size = data.buffer
		end
	end
end

function PT.rebuild_grid_from_scratch(grid, owner, grid_id, owner_type, player_index)
	local existing = storage.transformer_data[grid_id]
	local prev_in = existing and existing.allow_in
	local prev_out = existing and existing.allow_out
	if existing then
		destroy_proxy_pair(existing)
		storage.transformer_data[grid_id] = nil
	end

	local found_any = false
	for equip_name in pairs(PT.TRANSFORMER_TIERS) do
		for quality_name in pairs(prototypes.quality) do
			local count = grid.count({name = equip_name, quality = quality_name})
			if count > 0 then
				found_any = true
				for _ = 1, count do
					PT.equipment_inserted(owner, grid_id, equip_name, owner_type, quality_name, player_index)
				end
			end
		end
	end

	if found_any then
		local rebuilt = storage.transformer_data[grid_id]
		if rebuilt and prev_in ~= nil then
			rebuilt.allow_in = prev_in
			rebuilt.allow_out = prev_out
		end
		PT.refresh_grid_composition(grid, grid_id)
	end

	return found_any
end

function PT.new_vehicle_placed(entity, player_index)
	if not PT.is_vehicle_grid_allowed or not (entity and entity.valid) then return end

	storage.destroyed_registrations = storage.destroyed_registrations or {}

	local grid = entity.grid
	if grid and grid.valid then
		local grid_id = grid.unique_id
		storage.grid_vehicles[grid_id] = entity
		local reg_id = script.register_on_object_destroyed(entity)
		storage.destroyed_registrations[reg_id] = grid_id
		PT.rebuild_grid_from_scratch(grid, entity, grid_id, "entity", player_index)
	end
end

function PT.entity_removed(entity)
	if not PT.is_vehicle_grid_allowed or not entity then return end

	local grid_id
	for id, tracked_vehicle in pairs(storage.grid_vehicles) do
		if entity == tracked_vehicle then
			grid_id = id
			storage.grid_vehicles[id] = nil
			break
		end
	end

	if not grid_id then return end

	local data = storage.transformer_data[grid_id]
	if data and data.grid_owner_type == "entity" then
		destroy_proxy_pair(data)
		storage.transformer_data[grid_id] = nil
	end
end

function PT.on_object_destroyed(registration_number)
	storage.destroyed_registrations = storage.destroyed_registrations or {}
	local grid_id = storage.destroyed_registrations[registration_number]
	if not grid_id then return end

	storage.destroyed_registrations[registration_number] = nil
	storage.grid_vehicles[grid_id] = nil

	local data = storage.transformer_data[grid_id]
	if data and data.grid_owner_type == "entity" then
		destroy_proxy_pair(data)
		storage.transformer_data[grid_id] = nil
	end
end

function PT.get_player_for_grid(grid_id)
	for _, player in pairs(game.players) do
		if player.character and player.character.grid and player.character.grid.unique_id == grid_id then
			return player
		end
	end
	return nil
end

function PT.clear_player_transformers(player_index)
	for grid_id, data in pairs(storage.transformer_data) do
		if data.grid_owner_type == "player" and data.grid_owner_id == player_index then
			destroy_proxy_pair(data)
			storage.transformer_data[grid_id] = nil
		end
	end
	toggle_shortcut_available(game.players[player_index], false)
end

function PT.player_or_armor_changed(player_index)
	local player = game.players[player_index]
	if not (player and player.valid) then return end

	PT.clear_player_transformers(player_index)

	local character = player.character
	if not (character and character.valid) then return end

	local grid = character.grid
	if grid and grid.valid then
		local has_transformers = PT.rebuild_grid_from_scratch(grid, player, grid.unique_id, "player", player_index)
		toggle_shortcut_available(player, has_transformers)
	end
end

function PT.entity_teleported(entity)
	PT.entity_removed(entity)
	PT.new_vehicle_placed(entity)
end

function PT.purge_orphaned_entities()
	local active_entities = {}

	for _, data in pairs(storage.transformer_data) do
		local owner_surface = nil
		if data.grid_owner_type == "player" then
			local player = game.players[data.grid_owner_id]
			if player and player.valid and player.character and player.character.valid then
				owner_surface = player.character.surface
			end
		elseif data.grid_owner_type == "entity" then
			local vehicle = storage.grid_vehicles[data.grid_owner_id]
			if vehicle and vehicle.valid then
				owner_surface = vehicle.surface
			end
		end

		if data.input_entity and data.input_entity.valid then
			if not owner_surface or data.input_entity.surface ~= owner_surface then
				data.input_entity.destroy()
				data.input_entity = nil
			else
				active_entities[data.input_entity.unit_number] = true
			end
		end

		if data.output_entity and data.output_entity.valid then
			if not owner_surface or data.output_entity.surface ~= owner_surface then
				data.output_entity.destroy()
				data.output_entity = nil
			else
				active_entities[data.output_entity.unit_number] = true
			end
		end
	end

	for _, surface in pairs(game.surfaces) do
		for _, ent in pairs(surface.find_entities_filtered{name = PT.ENTITY_NAME_LIST}) do
			if ent.valid and not active_entities[ent.unit_number] then
				ent.destroy()
			end
		end
	end
end

function PT.pt_entity_cloned(original_entity, new_entity)
	for _, data in pairs(storage.transformer_data) do
		if data.input_entity == original_entity then
			data.input_entity = new_entity
			data.last_x = nil
			data.last_y = nil
			return
		elseif data.output_entity == original_entity then
			data.output_entity = new_entity
			data.last_x = nil
			data.last_y = nil
			return
		end
	end
end

function PT.migrate_and_rebuild_all()
	PT.init_storage()

	for _, data in pairs(storage.transformer_data) do
		if data.grid_transformer_entities then
			for _, old_ent in ipairs(data.grid_transformer_entities) do
				if old_ent and old_ent.valid then
					old_ent.destroy()
				end
			end
		end
		destroy_proxy_pair(data)
	end

	storage.transformer_data = {}
	storage.grid_vehicles = {}
	storage.destroyed_registrations = {}

	for _, player in pairs(game.players) do
		if player.valid and player.character and player.character.grid and player.character.grid.valid then
			local grid = player.character.grid
			local has_transformers = PT.rebuild_grid_from_scratch(grid, player, grid.unique_id, "player", player.index)
			toggle_shortcut_available(player, has_transformers)
		elseif player.valid then
			toggle_shortcut_available(player, false)
		end
	end

	if PT.is_vehicle_grid_allowed then
		for _, surface in pairs(game.surfaces) do
			for _, vehicle in pairs(surface.find_entities_filtered{type = PT.VEHICLE_TYPE_LIST}) do
				if vehicle.valid and vehicle.grid and vehicle.grid.valid then
					local grid = vehicle.grid
					local grid_id = grid.unique_id
					storage.grid_vehicles[grid_id] = vehicle
					local reg_id = script.register_on_object_destroyed(vehicle)
					storage.destroyed_registrations[reg_id] = grid_id
					PT.rebuild_grid_from_scratch(grid, vehicle, grid_id, "entity")
				end
			end
		end
	end

	PT.purge_orphaned_entities()
end

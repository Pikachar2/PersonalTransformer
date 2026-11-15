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
		input = "personal-transformer-input-entity",
		output = "personal-transformer-output-entity",
		draw = settings.startup["personal-transformer-mk1-flow-limit"].value * 1000
	},
	["personal-transformer-mk2-equipment"] = {
		input = "personal-transformer-mk2-input-entity",
		output = "personal-transformer-mk2-output-entity",
		draw = settings.startup["personal-transformer-mk2-flow-limit"].value * 1000
	},
	["personal-transformer-mk3-equipment"] = {
		input = "personal-transformer-mk3-input-entity",
		output = "personal-transformer-mk3-output-entity",
		draw = settings.startup["personal-transformer-mk3-flow-limit"].value * 1000
	}
}

PT.ENTITY_NAMES = {}
PT.ENTITY_NAME_LIST = {}
for _, tier in pairs(PT.TRANSFORMER_TIERS) do
	PT.ENTITY_NAMES[tier.input] = true
	PT.ENTITY_NAMES[tier.output] = true
	table.insert(PT.ENTITY_NAME_LIST, tier.input)
	table.insert(PT.ENTITY_NAME_LIST, tier.output)
end

function PT.init_storage()
	storage.transformer_data = storage.transformer_data or {}
	storage.grid_vehicles = storage.grid_vehicles or {}
end

-- Local caches and reusable scratch tables to minimize C++ API calls and GC churn
local EQUIP_FLOW_CACHE = {}
local scratch_eq = {}
local scratch_in = {}
local scratch_out = {}

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
			is_source = is_source
		}
	end

	by_name[quality_name] = info
	return info
end

local function teleport_entities_if_moved(data, target_pos, owner, owner_type, pt_entities)
	if owner_type == "player" and owner.controller_type == defines.controllers.remote then
		return
	end

	local tx = target_pos.x
	local ty = target_pos.y
	if data.last_x == tx and data.last_y == ty then
		return
	end

	data.last_x = tx
	data.last_y = ty

	for i = 1, #pt_entities do
		local pt_entity = pt_entities[i]
		if pt_entity.valid then
			pt_entity.teleport(target_pos)
		end
	end
end

local function process_grid_energy(grid, pt_entities, max_draw, buffer, tickdelay, allow_in, allow_out)
	local max_draw_in = 0
	local max_draw_out = 0
	local count = 0

	-- Pass 1: Gather equipment draw demands once and store in scratch tables
	for _, eq in pairs(grid.equipment) do
		local info = get_equipment_flow_info(eq)
		if info then
			local energy = eq.energy
			local d_in = 0
			local d_out = 0

			if allow_in and info.in_limit > 0 then
				local room = eq.max_energy - energy
				if room > 0 then
					local limit = info.in_limit * tickdelay
					d_in = (limit < room) and limit or room
					max_draw_in = max_draw_in + d_in
				end
			end

			if allow_out and info.is_source and info.out_limit > 0 and energy > 0 then
				local limit = info.out_limit * tickdelay
				d_out = (limit < energy) and limit or energy
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

	-- Early exit if nothing in the grid needs charging or can discharge
	if count == 0 then return end

	local avail_in = 0
	local request_out = buffer
	local num_pt = #pt_entities
	for i = 1, num_pt do
		local pt_entity = pt_entities[i]
		if pt_entity.valid then
			if pt_entity.type == "electric-energy-interface" then
				avail_in = avail_in + pt_entity.energy
			else
				request_out = request_out - pt_entity.energy
			end
		end
	end

	if avail_in <= 0 and request_out <= 0 then
		for i = 1, count do scratch_eq[i] = nil end
		return
	end

	local dt = tickdelay / 60
	local max_step_draw = max_draw * dt

	local drain_in = (avail_in > 0 and max_draw_in > 0) and math.min(max_draw_in / avail_in, 1) or 0
	local drain_out = (request_out > 0 and max_draw_out > 0) and math.min(max_draw_out / request_out, 1) or 0

	if avail_in > max_step_draw then avail_in = max_step_draw end
	if request_out > max_step_draw then request_out = max_step_draw end

	local ratio_in = (max_draw_in > 0 and avail_in > 0) and math.min(avail_in / max_draw_in, 1) or 0
	local ratio_out = (max_draw_out > 0 and request_out > 0) and math.min(request_out / max_draw_out, 1) or 0

	if drain_in > 0 or drain_out > 0 then
		for i = 1, num_pt do
			local pt_entity = pt_entities[i]
			if pt_entity.valid then
				if pt_entity.type == "electric-energy-interface" then
					if drain_in > 0 then
						pt_entity.energy = pt_entity.energy * (1 - drain_in)
					end
				elseif drain_out > 0 then
					local entity_buffer = pt_entity.electric_buffer_size
					pt_entity.energy = entity_buffer - ((entity_buffer - pt_entity.energy) * (1 - drain_out))
				end
			end
		end
	end

	-- Pass 2: Apply cached energy deltas and clear scratch references
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
				local allow_in = player.is_shortcut_toggled("toggle-equipment-transformer-input")
				local allow_out = player.is_shortcut_toggled("toggle-equipment-transformer-output")

				if allow_in or allow_out then
					teleport_entities_if_moved(data, player.position, player, "player", data.grid_transformer_entities)
					process_grid_energy(player.character.grid, data.grid_transformer_entities, data.max_grid_draw, data.buffer, tickdelay, allow_in, allow_out)
				end
			end
		elseif PT.is_vehicle_grid_allowed and data.grid_owner_type == "entity" then
			local vehicle = storage.grid_vehicles[data.grid_owner_id]
			if vehicle and vehicle.valid and vehicle.grid then
				teleport_entities_if_moved(data, vehicle.position, vehicle, "entity", data.grid_transformer_entities)
				process_grid_energy(vehicle.grid, data.grid_transformer_entities, data.max_grid_draw, data.buffer, tickdelay, true, true)
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

local function spawn_proxy_entities(tier, grid_owner, grid_id, quality_name)
	local entities = storage.transformer_data[grid_id].grid_transformer_entities
	local surface = grid_owner.surface
	local pos = grid_owner.position
	local force = grid_owner.force

	for _, entity_name in ipairs({tier.input, tier.output}) do
		local created = surface.create_entity{
			name = entity_name,
			position = pos,
			force = force,
			quality = quality_name
		}
		if created then
			entities[#entities + 1] = created
		end
	end
end

local function destroy_proxy_entities(tier, quality_name, grid_id)
	local entities = storage.transformer_data[grid_id].grid_transformer_entities
	for _, target_name in ipairs({tier.input, tier.output}) do
		for i = 1, #entities do
			local entity = entities[i]
			if not entity.valid or (entity.name == target_name and (quality_name == nil or entity.quality.name == quality_name)) then
				table.remove(entities, i)
				if entity.valid then entity.destroy() end
				break
			end
		end
	end
end

function PT.equipment_inserted(owner, grid_id, equipment_name, grid_owner_type, quality_name)
	local tier = PT.TRANSFORMER_TIERS[equipment_name]
	if not tier then return end

	local data = storage.transformer_data[grid_id]
	if not data then
		data = {
			grid_transformer_entities = {},
			transformer_count = {},
			max_grid_draw = 0
		}
		for name in pairs(PT.TRANSFORMER_TIERS) do
			data.transformer_count[name] = 0
		end
		storage.transformer_data[grid_id] = data
	end

	spawn_proxy_entities(tier, owner, grid_id, quality_name)
	data.transformer_count[equipment_name] = (data.transformer_count[equipment_name] or 0) + 1
	data.grid_owner_type = grid_owner_type

	if grid_owner_type == "player" then
		data.grid_owner_id = owner.index
		toggle_shortcut_available(owner, true)
	else
		data.grid_owner_id = grid_id
	end

	data.max_grid_draw = data.max_grid_draw + tier.draw
	data.buffer = data.max_grid_draw / 10
end

function PT.equipment_removed(grid_id, equipment_name, count, quality_name)
	local tier = PT.TRANSFORMER_TIERS[equipment_name]
	local data = storage.transformer_data[grid_id]
	if not tier or not data then return end

	for _ = 1, count do
		destroy_proxy_entities(tier, quality_name, grid_id)
	end

	data.transformer_count[equipment_name] = math.max((data.transformer_count[equipment_name] or 0) - count, 0)
	data.max_grid_draw = math.max(data.max_grid_draw - (tier.draw * count), 0)
	data.buffer = data.max_grid_draw / 10

	local total_count = 0
	for _, c in pairs(data.transformer_count) do
		total_count = total_count + c
	end

	if total_count == 0 then
		if data.grid_owner_type == "player" then
			toggle_shortcut_available(game.players[data.grid_owner_id], false)
		end
		storage.transformer_data[grid_id] = nil
	end
end

local function insert_grid_transformers(grid, owner, grid_id, owner_type)
	local found_any = false
	for equip_name in pairs(PT.TRANSFORMER_TIERS) do
		for quality_name in pairs(prototypes.quality) do
			local count = grid.count{name = equip_name, quality = quality_name}
			if count > 0 then
				found_any = true
				for _ = 1, count do
					PT.equipment_inserted(owner, grid_id, equip_name, owner_type, quality_name)
				end
			end
		end
	end
	return found_any
end

function PT.new_vehicle_placed(entity)
	if not PT.is_vehicle_grid_allowed or not (entity and entity.valid) then return end

	local grid = entity.grid
	if grid and grid.valid then
		local grid_id = grid.unique_id
		storage.grid_vehicles[grid_id] = entity
		insert_grid_transformers(grid, entity, grid_id, "entity")
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
	if data and data.grid_owner_type == "entity" and data.grid_owner_id == grid_id then
		for equip_name, count in pairs(data.transformer_count) do
			if count > 0 then
				PT.equipment_removed(grid_id, equip_name, count, nil)
			end
		end
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

function PT.player_or_armor_changed(player_index)
	local player = game.players[player_index]
	if not (player and player.valid and player.character) then return end
	if player.controller_type == defines.controllers.remote then return end

	for grid_id, data in pairs(storage.transformer_data) do
		if data.grid_owner_type == "player" and data.grid_owner_id == player_index then
			for equip_name, count in pairs(data.transformer_count) do
				if count > 0 then
					PT.equipment_removed(grid_id, equip_name, count, nil)
				end
			end
		end
	end

	local grid = player.character.grid
	if grid and grid.valid then
		local has_transformers = insert_grid_transformers(grid, player, grid.unique_id, "player")
		toggle_shortcut_available(player, has_transformers)
	else
		toggle_shortcut_available(player, false)
	end
end

function PT.entity_teleported(entity)
	PT.entity_removed(entity)
	PT.new_vehicle_placed(entity)
end

function PT.purge_orphaned_entities()
	if not PT.is_vehicle_grid_allowed then return end

	local active_entities = {}
	for _, data in pairs(storage.transformer_data) do
		local entities = data.grid_transformer_entities
		for i = 1, #entities do
			local pt_entity = entities[i]
			if pt_entity.valid then
				active_entities[pt_entity.unit_number] = true
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
		local entities = data.grid_transformer_entities
		for i = 1, #entities do
			if entities[i] == original_entity then
				entities[i] = new_entity
				data.last_x = nil
				data.last_y = nil
				return
			end
		end
	end
end

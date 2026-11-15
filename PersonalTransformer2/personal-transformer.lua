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

local function teleport_entities_to_owner(target_pos, owner, owner_type, pt_entities)
	if owner_type == "player" and owner.controller_type == defines.controllers.remote then
		return
	end

	for _, pt_entity in pairs(pt_entities) do
		if pt_entity.valid and (pt_entity.position.x ~= target_pos.x or pt_entity.position.y ~= target_pos.y) then
			pt_entity.teleport(target_pos)
		end
	end
end

local function process_grid_energy(grid, pt_entities, max_draw, buffer, tickdelay, allow_in, allow_out)
	local dt = tickdelay / 60
	local max_draw_in = 0
	local max_draw_out = 0

	for _, eq in pairs(grid.equipment) do
		local es = eq.prototype.energy_source
		if es and es.valid then
			if allow_in then
				max_draw_in = max_draw_in + math.max(math.min(es.get_input_flow_limit() * tickdelay, eq.max_energy - eq.energy), 0)
			end
			if allow_out and (eq.prototype.type == "battery-equipment" or eq.prototype.type == "generator-equipment") then
				max_draw_out = max_draw_out + math.min(es.get_output_flow_limit() * tickdelay, eq.energy)
			end
		end
	end

	local avail_in = 0
	local request_out = buffer
	for _, pt_entity in pairs(pt_entities) do
		if pt_entity.valid then
			if pt_entity.type == "electric-energy-interface" then
				avail_in = avail_in + pt_entity.energy
			else
				request_out = request_out - pt_entity.energy
			end
		end
	end

	local drain_in = (avail_in > 0) and math.min(math.max(max_draw_in / avail_in, 0), 1) or 0
	local drain_out = (request_out > 0) and math.min(math.max(max_draw_out / request_out, 0), 1) or 0

	avail_in = math.min(avail_in, max_draw * dt)
	request_out = math.min(request_out, max_draw * dt)

	local ratio_in = (max_draw_in > 0) and math.min(math.max(avail_in / max_draw_in, 0), 1) or 0
	local ratio_out = (max_draw_out > 0) and math.min(math.max(request_out / max_draw_out, 0), 1) or 0

	for _, pt_entity in pairs(pt_entities) do
		if pt_entity.valid then
			if pt_entity.type == "electric-energy-interface" then
				pt_entity.energy = pt_entity.energy * (1 - drain_in)
			else
				local entity_buffer = pt_entity.electric_buffer_size
				pt_entity.energy = entity_buffer - ((entity_buffer - pt_entity.energy) * (1 - drain_out))
			end
		end
	end

	for _, eq in pairs(grid.equipment) do
		local es = eq.prototype.energy_source
		if eq.name and es and es.valid then
			local draw_in = allow_in and math.max(math.min(es.get_input_flow_limit() * tickdelay, eq.max_energy - eq.energy), 0) or 0
			local draw_out = (allow_out and (eq.prototype.type == "battery-equipment" or eq.prototype.type == "generator-equipment"))
				and math.min(es.get_output_flow_limit() * tickdelay, eq.energy) or 0
			eq.energy = eq.energy + (draw_in * ratio_in) - (draw_out * ratio_out)
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
					teleport_entities_to_owner(player.position, player, "player", data.grid_transformer_entities)
					process_grid_energy(player.character.grid, data.grid_transformer_entities, data.max_grid_draw, data.buffer, tickdelay, allow_in, allow_out)
				end
			end
		elseif PT.is_vehicle_grid_allowed and data.grid_owner_type == "entity" then
			local vehicle = storage.grid_vehicles[data.grid_owner_id]
			if vehicle and vehicle.valid and vehicle.grid then
				teleport_entities_to_owner(vehicle.position, vehicle, "entity", data.grid_transformer_entities)
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
	for _, entity_name in ipairs({tier.input, tier.output}) do
		local created = grid_owner.surface.create_entity{
			name = entity_name,
			position = grid_owner.position,
			force = grid_owner.force,
			quality = quality_name
		}
		if created then
			table.insert(entities, created)
		end
	end
end

local function destroy_proxy_entities(tier, quality_name, grid_id)
	local entities = storage.transformer_data[grid_id].grid_transformer_entities
	for _, target_name in ipairs({tier.input, tier.output}) do
		for index, entity in ipairs(entities) do
			if not entity.valid or (entity.name == target_name and (quality_name == nil or entity.quality.name == quality_name)) then
				table.remove(entities, index)
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
		for _, pt_entity in ipairs(data.grid_transformer_entities) do
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
		for index, pt_entity in ipairs(data.grid_transformer_entities) do
			if pt_entity == original_entity then
				data.grid_transformer_entities[index] = new_entity
				return
			end
		end
	end
end

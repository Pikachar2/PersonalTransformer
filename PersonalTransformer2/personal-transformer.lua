local equipment_name = 'personal-transformer-equipment'
-- local personal_transformer_mk1_name = "personal-transformer-equipment"
-- local personal_transformer_mk2_name = "personal-transformer-mk2-equipment"
-- local personal_transformer_mk3_name = "personal-transformer-mk3-equipment"


---@param grid LuaEquipmentGrid
local function get_personal_transformer_equipment(grid)
	for _, quality in pairs(prototypes.quality)
	do
		local equipment = grid.find{name = equipment_name, quality = quality.name}
		if equipment ~= nil
		then
			return equipment
		end
	end
end

---@param grid LuaEquipmentGrid
---@param equipment_item LuaEquipment
---@return LuaEntity?
---@return LuaEntity?
local function create_personal_transformer_entities(grid, equipment_item)
	local inputEntity = grid.entity_owner.surface.create_entity{
		name = 'personal-transformer-input-entity',
		position = grid.entity_owner.position,
		force = grid.entity_owner.force,
		quality = equipment_item.quality,
	}
	if inputEntity
	then
		inputEntity.destructible = false
	end
	local outputEntity = grid.entity_owner.surface.create_entity{
		name = 'personal-transformer-output-entity',
		position = grid.entity_owner.position,
		force = grid.entity_owner.force,
		quality = equipment_item.quality,
	}
	if outputEntity
	then
		outputEntity.destructible = false
	end

    return inputEntity, outputEntity
end

local function init_storage()
	if storage.personal_transformer_per_grid == nil
	then
		storage.personal_transformer_per_grid = {}
	end
	if storage.personal_transformers == nil
	then
		storage.personal_transformers = {}
	end
end

local function is_close(pos_a, pos_b)
	return math.abs(pos_a.x - pos_b.x) + math.abs(pos_a.y - pos_b.y) < 2
end

script.on_nth_tick(8,
	function()
		init_storage()
		for entity, entity_data in pairs(storage.personal_transformers)
		do
			if not entity.valid
			then
				storage.personal_transformers[entity] = nil
			elseif not entity_data.grid or not entity_data.grid.valid or not entity_data.grid.entity_owner or not entity_data.grid.entity_owner.valid or entity_data.grid.entity_owner.grid ~= entity_data.grid
			then
				-- destroy if not valid
				entity.destroy()
			elseif entity_data.equipment ~= nil and entity_data.equipment.valid and entity_data.grid ~= nil and entity_data.grid.valid and entity_data.grid.entity_owner ~= nil and entity_data.grid.entity_owner.valid
			then
				-- transfer energy from the invisible lightning rod entity into the battery
				if entity.energy > 0
				then
					local old_energy = entity_data.equipment.energy
					entity_data.equipment.energy = entity_data.equipment.energy + entity.energy
					local new_energy = entity_data.equipment.energy
					entity.energy = entity.energy - (new_energy - old_energy)
				end
				local owner_position = entity_data.grid.entity_owner.position
				if entity.surface ~= entity_data.grid.entity_owner.surface
				then
					entity.destroy()
				elseif not is_close(entity.position, owner_position)
				then
					entity.teleport(owner_position)
				end
			end
		end
	end
)

script.on_init(function()
	for _, force in pairs(game.forces)
	do
		force.reset_technology_effects()
	end
end)

function get_grid_player_owner(grid)
	if grid
		and grid.valid
		and grid.entity_owner
		and grid.entity_owner.valid
		and grid.entity_owner.type == "character"
		and grid.entity_owner.player
	then
		return grid.entity_owner.player
	end
end

---@param grid LuaEquipmentGrid
function update_equipment_grid(grid)
	init_storage()
	if storage.personal_transformer_per_grid[grid.unique_id] ~= nil
	then
		local inputEntity = storage.personal_transformer_per_grid[grid.unique_id].input
		local outputEntity = storage.personal_transformer_per_grid[grid.unique_id].output
		storage.personal_transformers[inputEntity] = nil
		storage.personal_transformers[outputEntity] = nil
		storage.personal_transformer_per_grid[grid.unique_id] = nil
		if inputEntity.valid
		then
			inputEntity.destroy()
		end
		if outputEntity.valid
		then
			outputEntity.destroy()
		end
	end
	local equipment_item = get_personal_transformer_equipment(grid)
	local player = get_grid_player_owner(grid)
	local is_untoggled = player and not player.is_shortcut_toggled("toggle-equipment-transformer-input")
	if equipment_item ~= nil and equipment_item.valid and not is_untoggled
	then
		if grid.entity_owner ~= nil and grid.entity_owner.valid
		then
			local inputEntity, outputEntity = create_personal_transformer_entities(grid, equipment_item)
			if inputEntity ~= nil and outputEntity ~= nil
			then
				-- storage.personal_transformer_per_grid[grid.unique_id].input = inputEntity
				-- storage.personal_transformer_per_grid[grid.unique_id].output = outputEntity
				storage.personal_transformer_per_grid[grid.unique_id] = {input = inputEntity, output = outputEntity}
				storage.personal_transformers[inputEntity] = {grid = grid, equipment = equipment_item}
				storage.personal_transformers[outputEntity] = {grid = grid, equipment = equipment_item}
			end
		end
	end
end

function update_player_toggle_shortcut(player)
	local equipment_item = player and player.character and player.character.grid and get_personal_transformer_equipment(player.character.grid)
	player.set_shortcut_available("toggle-equipment-transformer-input", not not equipment_item)
end

function handle_toggle(event)
	local player = game.players[event.player_index]
	if player.is_shortcut_available("toggle-equipment-transformer-input")
	then
		player.set_shortcut_toggled("toggle-equipment-transformer-input", not player.is_shortcut_toggled("toggle-equipment-transformer-input"))
		if player.character and player.character.grid
		then
			update_equipment_grid(player.character.grid)
		end
	end
end

script.on_configuration_changed(
	function(event)
		for _, player in pairs(game.players)
		do
			update_player_toggle_shortcut(player)
			player.set_shortcut_toggled("toggle-equipment-transformer-input", false)
		end
		for collector, data in pairs(storage.personal_transformers or {})
		do
			local player = get_grid_player_owner(data.grid)
			if player
			then
				player.set_shortcut_toggled("toggle-equipment-transformer-input", true)
			end
		end
	end
)

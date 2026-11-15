local VEHICLE_GUI_FRAME_NAME = "pt_vehicle_toggle_frame"
local VEHICLE_GRID_FRAME_NAME = "pt_vehicle_grid_toggle_frame"
local VEHICLE_BTN_IN_NAME = "pt_vehicle_toggle_in"
local VEHICLE_BTN_OUT_NAME = "pt_vehicle_toggle_out"

local ENTITY_TYPE_TO_RELATIVE_GUI = {
	["car"] = defines.relative_gui_type.car_gui,
	["spider-vehicle"] = defines.relative_gui_type.spider_vehicle_gui,
	["cargo-wagon"] = defines.relative_gui_type.container_gui,
	["artillery-wagon"] = defines.relative_gui_type.container_gui
}

function PT.destroy_vehicle_gui(player)
	if not (player and player.valid) then return end
	local rel = player.gui.relative
	if rel[VEHICLE_GUI_FRAME_NAME] and rel[VEHICLE_GUI_FRAME_NAME].valid then
		rel[VEHICLE_GUI_FRAME_NAME].destroy()
	end
	if rel[VEHICLE_GRID_FRAME_NAME] and rel[VEHICLE_GRID_FRAME_NAME].valid then
		rel[VEHICLE_GRID_FRAME_NAME].destroy()
	end
end

local function create_anchored_frame(player, frame_name, gui_type, data)
	local frame = player.gui.relative.add{
		type = "frame",
		name = frame_name,
		caption = "Personal Transformer",
		direction = "vertical",
		anchor = {
			gui = gui_type,
			position = defines.relative_gui_position.right
		}
	}

	local flow = frame.add{
		type = "flow",
		name = "pt_toggle_flow",
		direction = "horizontal"
	}

	local btn_in = flow.add{
		type = "sprite-button",
		name = VEHICLE_BTN_IN_NAME,
		sprite = "pt-input-icon",
		tooltip = {"shortcut.toggle-equipment-transformer-input"},
		style = "shortcut_bar_button",
		auto_toggle = true,
		toggled = (data.allow_in ~= false)
	}
	btn_in.style.size = 36

	local btn_out = flow.add{
		type = "sprite-button",
		name = VEHICLE_BTN_OUT_NAME,
		sprite = "pt-output-icon",
		tooltip = {"shortcut.toggle-equipment-transformer-output"},
		style = "shortcut_bar_button",
		auto_toggle = true,
		toggled = (data.allow_out == true)
	}
	btn_out.style.size = 36
end

function PT.build_vehicle_gui(player, grid_id, entity_gui_type)
	PT.destroy_vehicle_gui(player)

	if not PT.is_vehicle_grid_allowed then return end
	local data = storage.transformer_data[grid_id]
	if not data or data.grid_owner_type ~= "entity" then return end

	storage.open_vehicle_guis = storage.open_vehicle_guis or {}
	storage.open_vehicle_guis[player.index] = {
		grid_id = grid_id,
		entity_gui_type = entity_gui_type
	}

	if entity_gui_type and entity_gui_type ~= defines.relative_gui_type.equipment_grid_gui then
		create_anchored_frame(player, VEHICLE_GUI_FRAME_NAME, entity_gui_type, data)
	end

	create_anchored_frame(player, VEHICLE_GRID_FRAME_NAME, defines.relative_gui_type.equipment_grid_gui, data)
end

function PT.refresh_open_vehicle_guis(grid_id)
	if not storage.open_vehicle_guis then return end

	local data = storage.transformer_data[grid_id]
	local has_transformers = (data ~= nil and data.grid_owner_type == "entity")

	for player_index, view_info in pairs(storage.open_vehicle_guis) do
		if view_info.grid_id == grid_id then
			local player = game.players[player_index]
			if player and player.valid then
				if has_transformers then
					PT.build_vehicle_gui(player, grid_id, view_info.entity_gui_type)
				else
					PT.destroy_vehicle_gui(player)
				end
			end
		end
	end
end

function PT.handle_gui_opened(event)
	local player = game.players[event.player_index]
	if not (player and player.valid) then return end

	if event.gui_type == defines.gui_type.entity and event.entity and event.entity.valid then
		local entity = event.entity
		if PT.VEHICLE_TYPES[entity.type] and entity.grid and entity.grid.valid then
			local grid_id = entity.grid.unique_id
			local rel_gui = ENTITY_TYPE_TO_RELATIVE_GUI[entity.type]
			storage.open_vehicle_guis = storage.open_vehicle_guis or {}
			storage.open_vehicle_guis[player.index] = {
				grid_id = grid_id,
				entity_gui_type = rel_gui
			}
			PT.build_vehicle_gui(player, grid_id, rel_gui)
		end
	elseif event.gui_type == defines.gui_type.equipment_grid and event.grid and event.grid.valid then
		local grid_id = event.grid.unique_id
		if storage.grid_vehicles[grid_id] then
			storage.open_vehicle_guis = storage.open_vehicle_guis or {}
			storage.open_vehicle_guis[player.index] = {
				grid_id = grid_id,
				entity_gui_type = nil
			}
			PT.build_vehicle_gui(player, grid_id, nil)
		end
	end
end

function PT.handle_gui_closed(event)
	local player = game.players[event.player_index]
	if not (player and player.valid) then return end

	if player.opened then
		return
	end

	PT.destroy_vehicle_gui(player)
	if storage.open_vehicle_guis then
		storage.open_vehicle_guis[event.player_index] = nil
	end
end

local function sync_frame_buttons(frame, allow_in, allow_out)
	local flow = frame and frame.valid and frame.pt_toggle_flow
	if flow then
		flow[VEHICLE_BTN_IN_NAME].toggled = allow_in
		flow[VEHICLE_BTN_OUT_NAME].toggled = allow_out
	end
end

function PT.handle_gui_click(event)
	local element = event.element
	if not (element and element.valid) then return end

	local name = element.name
	if name ~= VEHICLE_BTN_IN_NAME and name ~= VEHICLE_BTN_OUT_NAME then return end

	local player = game.players[event.player_index]
	if not (player and player.valid) then return end

	local view_info = storage.open_vehicle_guis and storage.open_vehicle_guis[player.index]
	local grid_id = view_info and view_info.grid_id
	local data = grid_id and storage.transformer_data[grid_id]
	if not data then
		PT.destroy_vehicle_gui(player)
		return
	end

	if name == VEHICLE_BTN_IN_NAME then
		data.allow_in = element.toggled
	else
		data.allow_out = element.toggled
	end

	local allow_in = (data.allow_in ~= false)
	local allow_out = (data.allow_out == true)

	for p_idx, other_view in pairs(storage.open_vehicle_guis) do
		if other_view.grid_id == grid_id then
			local other = game.players[p_idx]
			if other and other.valid then
				local rel = other.gui.relative
				sync_frame_buttons(rel[VEHICLE_GUI_FRAME_NAME], allow_in, allow_out)
				sync_frame_buttons(rel[VEHICLE_GRID_FRAME_NAME], allow_in, allow_out)
			end
		end
	end
end

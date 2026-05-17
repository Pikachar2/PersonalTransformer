require("personal-transformer")


script.on_event(
	defines.events.on_equipment_inserted,
	function (event)
		local player = get_grid_player_owner(event.grid)
		if player
		then
			local was_available = player.is_shortcut_available("toggle-equipment-transformer-input")
			update_player_toggle_shortcut(player)
			local is_available = player.is_shortcut_available("toggle-equipment-transformer-input")
			if is_available and not was_available
			then
				player.set_shortcut_toggled("toggle-equipment-transformer-input", true)
			end
		end
		update_equipment_grid(event.grid)
	end
)

script.on_event(
	defines.events.on_player_created,
	function (event)
		local player = game.players[event.player_index]
		if player
		then
			update_player_toggle_shortcut(player)
		end
	end
)

script.on_event(
	defines.events.on_equipment_removed,
	function (event)
		local player = get_grid_player_owner(event.grid)
		if player
		then
			update_player_toggle_shortcut(player)
		end
		update_equipment_grid(event.grid)
	end
)

script.on_event(
	defines.events.on_player_changed_surface,
	function(event)
		local player = game.players[event.player_index]
		if player.character and player.character.grid
		then
			update_equipment_grid(player.character.grid)
		end
	end
)

script.on_event(
	defines.events.on_built_entity,
	function(event)
		if event.entity.grid
		then
			update_equipment_grid(event.entity.grid)
		end
	end
)

script.on_event(
	defines.events.on_robot_built_entity,
	function(event)
		if event.entity.grid
		then
			update_equipment_grid(event.entity.grid)
		end
	end
)

script.on_event("toggle-equipment-transformer-input", handle_toggle)

script.on_event(defines.events.on_lua_shortcut,
	function(event)
		if event.prototype_name == "toggle-equipment-transformer-input"
		then
			handle_toggle(event)
		end
	end
)

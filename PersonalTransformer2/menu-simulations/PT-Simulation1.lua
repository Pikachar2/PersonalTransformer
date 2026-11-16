local surface = game.surfaces.nauvis

-- Center camera on the Factorio logo
local _, logo = next(surface.find_entities_filtered{
	name = {"factorio-logo-11tiles", "factorio-logo-16tiles", "factorio-logo-22tiles"},
	limit = 1
})
if logo and logo.valid then
	game.simulation.camera_position = {logo.position.x, logo.position.y + 9.75}
else
	game.simulation.camera_position = {0, 0}
end
game.simulation.camera_zoom = 1
game.tick_paused = false

-- Detach any saved player from the character so Factorio hides the HUD
for _, player in pairs(game.players) do
	if player.character then
		player.character = nil
	end
	player.set_controller{type = defines.controllers.ghost}
end

-- Clean up any leftover proxy entities saved inside the map
for _, ent in pairs(surface.find_entities_filtered{name = {
	"personal-transformer-input-entity",
	"personal-transformer-output-entity",
	"personal-transformer-mk2-input-entity",
	"personal-transformer-mk2-output-entity",
	"personal-transformer-mk3-input-entity",
	"personal-transformer-mk3-output-entity"
}}) do
	if ent.valid then ent.destroy() end
end

local _, character = next(surface.find_entities_filtered{name = "character", limit = 1})
local _, loco = next(surface.find_entities_filtered{type = "locomotive", limit = 1})
local start_tick = game.tick
local has_boarded = false
local exit_target = nil
local enable_at_tick = nil
local sim_in = nil
local sim_out = nil

local function step_character_toward(char, target_pos, speed)
	local dx = target_pos.x - char.position.x
	local dy = target_pos.y - char.position.y
	local dist = math.sqrt(dx * dx + dy * dy)

	local dir
	if math.abs(dx) > math.abs(dy) then
		dir = (dx > 0) and defines.direction.east or defines.direction.west
	else
		dir = (dy > 0) and defines.direction.south or defines.direction.north
	end

	char.direction = dir
	char.walking_state = {walking = true, direction = dir}

	if speed >= dist then
		char.walking_state = {walking = false, direction = dir}
		char.teleport({target_pos.x, target_pos.y})
		return true
	end

	char.teleport({
		char.position.x + (dx / dist) * speed,
		char.position.y + (dy / dist) * speed
	})
	return false
end

script.on_nth_tick(1, function(event)
	if not (character and character.valid) then return end

	-- Spawn proxy entities 60 ticks (1.0 second) after exiting the train
	if enable_at_tick and event.tick >= enable_at_tick then
		enable_at_tick = nil
		sim_in = surface.create_entity{name = "personal-transformer-input-entity", position = character.position, force = character.force}
		sim_out = surface.create_entity{name = "personal-transformer-output-entity", position = character.position, force = character.force}
		if sim_in then sim_in.electric_buffer_size = 400000 end
		if sim_out then
			sim_out.electric_buffer_size = 400000
			sim_out.energy = 0
		end
	end

	-- Transfer power only after proxies are spawned
	if sim_in and sim_in.valid and sim_out and sim_out.valid then
		sim_in.teleport(character.position)
		sim_out.teleport(character.position)

		local grid = character.grid
		if grid and grid.valid then
			for _, eq in pairs(grid.equipment) do
				if sim_in.energy > 0 and eq.max_energy > eq.energy then
					local pull = math.min(sim_in.energy, eq.max_energy - eq.energy, 66666)
					eq.energy = eq.energy + pull
					sim_in.energy = sim_in.energy - pull
				elseif eq.energy > 0 and sim_out.electric_buffer_size > sim_out.energy then
					local push = math.min(eq.energy, sim_out.electric_buffer_size - sim_out.energy, 66666)
					eq.energy = eq.energy - push
					sim_out.energy = sim_out.energy + push
				end
			end
		end
	end

	-- Phase 1: Walk to locomotive and board
	if not has_boarded and loco and loco.valid and (event.tick - start_tick) > 20 then
		local dx = loco.position.x - character.position.x
		local dy = loco.position.y - character.position.y
		if 4.0 >= (dx * dx + dy * dy) then
			character.walking_state = {walking = false}
			loco.set_driver(character)
			has_boarded = true
		else
			step_character_toward(character, loco.position, 0.14)
		end
	end

	-- Phase 2: Walk onto outpost platform after exiting train
	if exit_target and not character.driving then
		if step_character_toward(character, exit_target, 0.14) then
			exit_target = nil
		end
	end
end)

-- Exit on the right side of the train when it arrives at the destination stop
script.on_event(defines.events.on_train_changed_state, function(event)
	local train = event.train
	if train.state == defines.train_state.wait_station and character and character.valid and character.driving then
		character.driving = false
		if loco and loco.valid then
			local right_side = surface.find_non_colliding_position("character", {loco.position.x + 2, loco.position.y}, 5, 0.5)
			if right_side then
				character.teleport(right_side)
			else
				character.teleport({loco.position.x + 2, loco.position.y})
			end
		end
		enable_at_tick = game.tick + 60
		exit_target = {
			x = character.position.x + 2.5,
			y = character.position.y
		}
	end
end)

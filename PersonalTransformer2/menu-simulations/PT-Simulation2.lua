local surface = game.surfaces.nauvis

-- Center camera on the Factorio logo
local _, logo = next(surface.find_entities_filtered{
	name = {"factorio-logo-11tiles", "factorio-logo-16tiles", "factorio-logo-22tiles"},
	limit = 1
})
if logo and logo.valid then
	game.simulation.camera_position = {logo.position.x, logo.position.y + 9.75}
else
	game.simulation.camera_position = {4, -0.25}
end
game.simulation.camera_zoom = 1
game.tick_paused = false

-- Hide player HUD completely
for _, player in pairs(game.players) do
	if player.character then
		player.character = nil
	end
	player.set_controller{type = defines.controllers.ghost}
end

-- Remove any baked-in proxy entities from the save
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

-- Set midnight lighting so the glowing lamps stand out clearly
surface.daytime = 0.5
surface.freeze_daytime = true

-- Running track: top at y = -9.5, bottom at y = 9.0
local waypoints = {
	{x = -3.0, y = -9.5}, -- Top-Left (Lap Start/Finish)
	{x = 12.0, y = -9.5}, -- Top-Right
	{x = 12.0, y = 9.0},  -- Bottom-Right
	{x = -3.0, y = 9.0}   -- Bottom-Left
}
local current_wp = 2 -- Start at Top-Left (wp 1) and run straight toward Top-Right (wp 2)
local laps_completed = 0
local biters_chasing = false

-- Find the runner character (the one equipped with Power Armor MK2)
local runner = nil
for _, char in pairs(surface.find_entities_filtered{name = "character"}) do
	if char.valid and char.grid and char.grid.valid then
		runner = char
		break
	end
end
if not runner then
	_, runner = next(surface.find_entities_filtered{name = "character", limit = 1})
end

-- Snap runner once at tick 0 to Top-Left corner and fine-tune running speed
if runner and runner.valid then
	runner.teleport({-3.0, -9.5})
	runner.character_running_speed_modifier = -0.18
end

-- Find the Spidertron hidden behind the menu, seat a hidden driver inside it, and record its home anchor
local _, spider = next(surface.find_entities_filtered{type = "spider-vehicle", limit = 1})
local spider_anchor = (spider and spider.valid) and {x = spider.position.x, y = spider.position.y} or nil
if spider and spider.valid and not spider.get_driver() then
	local spider_driver = surface.create_entity{
		name = "character",
		position = spider.position,
		force = spider.force
	}
	if spider_driver then
		spider.set_driver(spider_driver)
	end
end

-- Find the Tank, seat a hidden driver inside it, and ensure it has fuel to spin in place
local _, tank = next(surface.find_entities_filtered{name = "tank", limit = 1})
if tank and tank.valid then
	if not tank.get_driver() then
		local tank_driver = surface.create_entity{
			name = "character",
			position = tank.position,
			force = tank.force
		}
		if tank_driver then
			tank.set_driver(tank_driver)
		end
	end
	local fuel_inv = tank.get_fuel_inventory()
	if fuel_inv and fuel_inv.is_empty() then
		fuel_inv.insert{name = "nuclear-fuel", count = 1}
	end
end

-- Find all friendly biters and track each biter's current corner waypoint
local biter_runners = {}
for _, biter in pairs(surface.find_entities_filtered{type = "unit"}) do
	if biter.valid and biter.commandable then
		biter.commandable.set_command{
			type = defines.command.stop,
			distraction = defines.distraction.none
		}
		table.insert(biter_runners, {entity = biter, wp = 1})
	end
end

local function send_biter_to_waypoint(entry)
	local biter = entry.entity
	local target = waypoints[entry.wp]
	if biter and biter.valid and biter.commandable and target then
		biter.commandable.set_command{
			type = defines.command.go_to_location,
			destination = {target.x, target.y},
			radius = 0.8,
			distraction = defines.distraction.none
		}
	end
end

-- Spawn the Personal Transformer proxy pair on the runner
local sim_in = runner and surface.create_entity{
	name = "personal-transformer-input-entity",
	position = runner.position,
	force = runner.force
}
local sim_out = runner and surface.create_entity{
	name = "personal-transformer-output-entity",
	position = runner.position,
	force = runner.force
}
if sim_in then sim_in.electric_buffer_size = 4000000 end
if sim_out then
	sim_out.electric_buffer_size = 4000000
	sim_out.energy = 0
end

local function get_direction_to(from_pos, to_pos)
	local dx = to_pos.x - from_pos.x
	local dy = to_pos.y - from_pos.y
	if math.abs(dx) > math.abs(dy) then
		return (dx > 0) and defines.direction.east or defines.direction.west
	else
		return (dy > 0) and defines.direction.south or defines.direction.north
	end
end

script.on_nth_tick(1, function(event)
	-- Keep Spidertron body hidden behind the menu while continuously stepping its front legs onto the circle belts
	if spider and spider.valid and spider_anchor then
		if (event.tick % 20) == 0 then
			local offset = ((event.tick % 40) == 0) and 1.2 or -1.2
			spider.autopilot_destination = {spider_anchor.x + offset, spider_anchor.y}
		end
	end

	-- Spin the Tank counter-clockwise in place
	if tank and tank.valid then
		tank.riding_state = {
			acceleration = defines.riding.acceleration.nothing,
			direction = defines.riding.direction.left
		}
	end

	if not (runner and runner.valid) then return end

	local target = waypoints[current_wp]
	local dx = target.x - runner.position.x
	local dy = target.y - runner.position.y
	local dist = math.sqrt(dx * dx + dy * dy)

	-- Switch to the next corner as soon as the runner reaches within 0.6 tiles
	if 0.6 >= dist then
		-- Reaching waypoint 1 (Top-Left) completes a full lap
		if current_wp == 1 then
			laps_completed = laps_completed + 1
			if laps_completed >= 1 and not biters_chasing then
				biters_chasing = true
				for _, entry in ipairs(biter_runners) do
					entry.wp = 1
					send_biter_to_waypoint(entry)
				end
			end
		end

		current_wp = (current_wp % #waypoints) + 1
		target = waypoints[current_wp]
	end

	-- Advance each biter through the lap waypoints once the chase begins
	if biters_chasing then
		for _, entry in ipairs(biter_runners) do
			local biter = entry.entity
			if biter and biter.valid then
				local b_target = waypoints[entry.wp]
				local bdx = b_target.x - biter.position.x
				local bdy = b_target.y - biter.position.y
				if 1.2 >= math.sqrt(bdx * bdx + bdy * bdy) then
					entry.wp = (entry.wp % #waypoints) + 1
					send_biter_to_waypoint(entry)
				end
			end
		end
	end

	-- Let Factorio's native movement engine move the character smoothly
	local dir = get_direction_to(runner.position, target)
	runner.walking_state = {walking = true, direction = dir}

	-- Keep proxy entities synced to runner position
	if sim_in and sim_in.valid then sim_in.teleport(runner.position) end
	if sim_out and sim_out.valid then sim_out.teleport(runner.position) end

	-- Keep armor batteries and output proxy buffer energized for continuous laps
	local grid = runner.grid
	if grid and grid.valid and sim_out and sim_out.valid then
		for _, eq in pairs(grid.equipment) do
			if eq.max_energy > 0 then
				eq.energy = eq.max_energy
			end
		end
		if sim_out.electric_buffer_size > sim_out.energy then
			sim_out.energy = sim_out.electric_buffer_size
		end
	end
end)

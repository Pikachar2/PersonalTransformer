local uc = data.raw["utility-constants"]["default"]

-- Keep only one existing simulation alongside your mod's simulations while testing
-- (Delete lines 4-8 before release to restore all base-game and modded simulations)
local first_key, first_sim = next(uc.main_menu_simulations)
uc.main_menu_simulations = {}
if first_key and first_sim then
	uc.main_menu_simulations[first_key] = first_sim
end

uc.main_menu_simulations.pt_simulation_1 = {
	checkboard = false,
	save = "__PersonalTransformer2__/menu-simulations/PT-Simulation1.zip",
	length = 60 * 18,
	init = [[require("__PersonalTransformer2__/menu-simulations/PT-Simulation1")]]
}

uc.main_menu_simulations.pt_simulation_2 = {
	checkboard = false,
	save = "__PersonalTransformer2__/menu-simulations/PT-Simulation2.zip",
	length = 60 * 20,
	init = [[require("__PersonalTransformer2__/menu-simulations/PT-Simulation2")]]
}

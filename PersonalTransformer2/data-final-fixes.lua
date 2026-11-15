local TRANSFORMER_ITEMS = {
	"personal-transformer-equipment",
	"personal-transformer-mk2-equipment",
	"personal-transformer-mk3-equipment"
}

local VEHICLE_PROTOTYPE_TYPES = {
	"car",
	"spider-vehicle",
	"locomotive",
	"cargo-wagon",
	"fluid-wagon",
	"artillery-wagon"
}

local function normalize_categories(cats)
	if type(cats) == "string" then
		return {cats}
	elseif type(cats) == "table" then
		return table.deepcopy(cats)
	end
	return {}
end

local function has_category(cat_list, target)
	for _, c in ipairs(cat_list) do
		if c == target then return true end
	end
	return false
end

local grids = data.raw["equipment-grid"]
local items = data.raw["battery-equipment"]

if grids and items then
	if settings.startup["personal-transformer2-allow-non-armor"].value then
		-- Allow transformers in ALL equipment grids
		local seen_categories = {}
		local all_categories = {}

		for _, grid in pairs(grids) do
			for _, c in ipairs(normalize_categories(grid.equipment_categories)) do
				if not seen_categories[c] then
					seen_categories[c] = true
					table.insert(all_categories, c)
				end
			end
		end

		for _, item_name in ipairs(TRANSFORMER_ITEMS) do
			if items[item_name] then
				items[item_name].categories = all_categories
			end
		end
	else
		-- Restrict transformers strictly to character armor grids
		local vehicle_grids = {}
		for _, v_type in ipairs(VEHICLE_PROTOTYPE_TYPES) do
			if data.raw[v_type] then
				for _, vehicle in pairs(data.raw[v_type]) do
					if vehicle.equipment_grid then
						vehicle_grids[vehicle.equipment_grid] = true
					end
				end
			end
		end

		local cloned_armor_grids = {}
		for _, armor in pairs(data.raw.armor) do
			local grid_name = armor.equipment_grid
			local grid = grid_name and grids[grid_name]
			if grid then
				local cats = normalize_categories(grid.equipment_categories)
				if has_category(cats, "armor") then
					if vehicle_grids[grid_name] then
						-- Vehicle shares this grid prototype; clone an armor-only version
						local armor_grid_name = "pt-armor-" .. grid_name
						if not cloned_armor_grids[armor_grid_name] then
							local new_grid = table.deepcopy(grid)
							new_grid.name = armor_grid_name
							new_grid.equipment_categories = normalize_categories(new_grid.equipment_categories)
							if not has_category(new_grid.equipment_categories, "armor-transformer") then
								table.insert(new_grid.equipment_categories, "armor-transformer")
							end
							data:extend({new_grid})
							cloned_armor_grids[armor_grid_name] = true
						end
						armor.equipment_grid = armor_grid_name
					else
						-- Grid is exclusive to armor; add category directly
						grid.equipment_categories = cats
						if not has_category(grid.equipment_categories, "armor-transformer") then
							table.insert(grid.equipment_categories, "armor-transformer")
						end
					end
				end
			end
		end

		for _, item_name in ipairs(TRANSFORMER_ITEMS) do
			if items[item_name] then
				items[item_name].categories = {"armor-transformer"}
			end
		end
	end
end

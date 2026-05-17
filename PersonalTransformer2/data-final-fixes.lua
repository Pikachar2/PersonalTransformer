local grids = data.raw["equipment-grid"]
data:extend({
  {
    type = "equipment-category",
    name = "vehicle-transformer"
  }
})
local items = data.raw["battery-equipment"]

local equipment_categories = {}

local function contains(table, val)
    for i=1,#table do
        if table[i] == val then
            return true
        end
    end
    return false
end

if grids then
    if settings.startup["personal-transformer2-allow-non-armor"].value then
        for _, grid in pairs(grids) do
            for _, c in pairs(grid.equipment_categories) do
                if not contains(equipment_categories, c)then
                    table.insert(equipment_categories, c)
                end
            end
       end

        if items then
            for _, item in pairs(items) do
                if item.name and string.find(item.name, "transformer") then
                    item.categories = item.categories or {}

                    -- force correct category alignment
                    item.categories = equipment_categories
                end
            end
        end
    end
end



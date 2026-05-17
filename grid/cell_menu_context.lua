--[[ Context for banner.widgets.<type> cell_menu providers (grid editor). ]]
local Settings = require("settings")

local M = {}

--- @param placement_index integer index in Settings:getGridPlacements() (anchor)
function M.new(placement_index, row, col, pop_menu_one_level)
    local function pop_menu(touchmenu)
        if type(pop_menu_one_level) == "function" and touchmenu then
            pop_menu_one_level(touchmenu)
        end
    end

    local function read_placement()
        local pl = Settings:getGridPlacements()
        return pl[placement_index]
    end

    --- @param fn fun(p: table)
    local function mutate(fn)
        local pl = Settings:getGridPlacements()
        local p = pl[placement_index]
        if not p then
            return
        end
        fn(p)
        Settings:saveGridPlacements(pl)
    end

    return {
        placement_index = placement_index,
        row = row,
        col = col,
        pop_menu = pop_menu,
        read_placement = read_placement,
        mutate = mutate,
    }
end

return M

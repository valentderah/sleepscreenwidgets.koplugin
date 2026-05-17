--[[ Square cell metrics + inner padding when the grid fits in a taller inner area.]]

local LayoutSpec = require("grid.layout_spec")

local M = {}

--- @return slot_w integer, row_h integer, pad_x integer, pad_y integer
function M.slot_and_padding(inner_w, inner_h, grid_cols, grid_rows, gutter_x, gutter_y)
    local sw_fallback, rh_fallback = LayoutSpec.slot_and_row_height(
        inner_w,
        inner_h,
        grid_cols,
        grid_rows,
        gutter_x,
        gutter_y
    )

    gutter_x = math.max(0, gutter_x or 0)
    gutter_y = math.max(0, gutter_y or 0)
    grid_cols = math.max(1, grid_cols)
    grid_rows = math.max(1, grid_rows)

    local usable_w = inner_w - (grid_cols - 1) * gutter_x
    local usable_h = inner_h - (grid_rows - 1) * gutter_y
    local max_s_w = math.max(1, math.floor(usable_w / grid_cols))
    local max_s_h = math.max(1, math.floor(usable_h / grid_rows))
    local s = math.min(max_s_w, max_s_h)
    if s < 1 then
        return sw_fallback, rh_fallback, 0, 0
    end
    local used_w = grid_cols * s + (grid_cols - 1) * gutter_x
    local used_h = grid_rows * s + (grid_rows - 1) * gutter_y
    local pad_x = math.max(0, math.floor((inner_w - used_w) / 2))
    local pad_y = math.max(0, math.floor((inner_h - used_h) / 2))
    return s, s, pad_x, pad_y
end

return M

--[[ Layout in px from screen + banner_dp + grid dimensions (pure Lua, no KOReader UI widgets).
    Экспортирует также «сырьевую» геометрию слота / span (ранее модуль grid.grid_geometry). ]]

local GridModel = require("grid.grid_model")
local Config = require("config")

local M = {}

--- @param inner_w integer drawable width inside edge margins
--- @param inner_h integer total grid height
--- @param grid_cols integer
--- @param grid_rows integer
--- @param gutter_x integer horizontal gap between columns (count = grid_cols - 1)
--- @param gutter_y integer vertical gap between rows (count = grid_rows - 1)
function M.slot_and_row_height(inner_w, inner_h, grid_cols, grid_rows, gutter_x, gutter_y)
    grid_cols = math.max(1, grid_cols)
    grid_rows = math.max(1, grid_rows)
    gutter_x = math.max(0, gutter_x)
    gutter_y = math.max(0, gutter_y)
    local inner_cols = inner_w - (grid_cols - 1) * gutter_x
    local inner_rows = inner_h - (grid_rows - 1) * gutter_y
    local slot_w = math.max(1, math.floor(inner_cols / grid_cols))
    local row_h = math.max(1, math.floor(inner_rows / grid_rows))
    return slot_w, row_h
end

function M.merged_span_width(slot_w, gutter_x, col_span)
    col_span = math.max(1, col_span)
    return col_span * slot_w + (col_span - 1) * gutter_x
end

local function identity(n)
    return n
end

--- @param args table|nil
--- @field screen_w number
--- @field screen_h number
--- @field grid_inner_h number|nil base height before top/bottom edge subtract
--- @field scale_by_size function|nil maps dp-like values to px (default identity)
--- @field banner_dp table|nil from `require("grid.banner_dp").effective_dp(...)`
function M.compute(args)
    args = type(args) == "table" and args or {}
    local screen_w = tonumber(args.screen_w) or 0
    local screen_h = tonumber(args.screen_h) or 0
    local inner_base_h = tonumber(args.grid_inner_h)
    if inner_base_h == nil then
        inner_base_h = screen_h
    end
    local scale_by_size = args.scale_by_size
    if type(scale_by_size) ~= "function" then
        scale_by_size = identity
    end
    local banner_dp = args.banner_dp
    if type(banner_dp) ~= "table" then
        banner_dp = {}
    end

    local inner_min_px = assert(Config.GRID_LAYOUT.inner_min_px)

    local edge_ml_px = scale_by_size(tonumber(banner_dp.grid_edge_margin_left_dp) or 0)
    local edge_mr_px = scale_by_size(tonumber(banner_dp.grid_edge_margin_right_dp) or 0)
    local edge_mt_px = scale_by_size(tonumber(banner_dp.grid_edge_margin_top_dp) or 0)
    local edge_mb_px = scale_by_size(tonumber(banner_dp.grid_edge_margin_bottom_dp) or 0)

    local inner_w_px = math.max(inner_min_px, screen_w - edge_ml_px - edge_mr_px)
    local inner_h_px = math.max(inner_min_px, inner_base_h - edge_mt_px - edge_mb_px)

    local gutter_x_px = scale_by_size(tonumber(banner_dp.grid_gutter_x_dp) or 0)
    local gutter_y_px = scale_by_size(tonumber(banner_dp.grid_gutter_y_dp) or 0)

    local slot_w_px, row_h_px = M.slot_and_row_height(
        inner_w_px,
        inner_h_px,
        GridModel.GRID_COLS,
        GridModel.GRID_ROWS,
        gutter_x_px,
        gutter_y_px
    )

    return {
        edge_ml_px = edge_ml_px,
        edge_mr_px = edge_mr_px,
        edge_mt_px = edge_mt_px,
        edge_mb_px = edge_mb_px,
        inner_w_px = inner_w_px,
        inner_h_px = inner_h_px,
        gutter_x_px = gutter_x_px,
        gutter_y_px = gutter_y_px,
        slot_w_px = slot_w_px,
        row_h_px = row_h_px,
    }
end

return M

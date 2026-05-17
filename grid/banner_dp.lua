--[[ Merged `banner` table → normalized dp integers for layout and menus (pure Lua). ]]
local Config = require("config")

local M = {}

local INSET_MAX = assert(tonumber(Config.GRID_EDGE_INSET_MAX), "GRID_EDGE_INSET_MAX")
local DEF = Config.DEFAULT_BANNER

function M.clamp_dp(n)
    n = math.floor(tonumber(n) or 0)
    return math.max(0, math.min(INSET_MAX, n))
end

local function sym_x(banner)
    local x = tonumber(banner.grid_edge_margin_x)
    if x == nil then
        x = tonumber(banner.grid_edge_margin)
    end
    if x == nil then
        x = DEF.grid_edge_margin_x
    end
    return M.clamp_dp(x)
end

local function sym_y(banner)
    local y = tonumber(banner.grid_edge_margin_y)
    if y == nil then
        y = tonumber(banner.grid_edge_margin)
    end
    if y == nil then
        y = DEF.grid_edge_margin_y
    end
    return M.clamp_dp(y)
end

local function pick_side(banner, key, sym_fb)
    local v = tonumber(banner[key])
    if v == nil then
        return sym_fb
    end
    return M.clamp_dp(v)
end

function M.symm_edge_x_dp(merged_banner)
    return sym_x(merged_banner or {})
end

function M.symm_edge_y_dp(merged_banner)
    return sym_y(merged_banner or {})
end

function M.edge_margins_dp(merged_banner)
    local b = merged_banner or {}
    local sx = sym_x(b)
    local sy = sym_y(b)
    return {
        left_dp = pick_side(b, "grid_edge_margin_left", sx),
        right_dp = pick_side(b, "grid_edge_margin_right", sx),
        top_dp = pick_side(b, "grid_edge_margin_top", sy),
        bottom_dp = pick_side(b, "grid_edge_margin_bottom", sy),
    }
end

function M.widget_gap_dp(merged_banner)
    local b = merged_banner or {}
    if tonumber(b.widget_gap) ~= nil then
        return M.clamp_dp(b.widget_gap)
    end
    return M.clamp_dp(DEF.widget_gap)
end

function M.grid_gutter_x_dp(merged_banner)
    local b = merged_banner or {}
    local v = tonumber(b.grid_gutter_x)
    if v == nil then
        v = tonumber(b.widget_gap) or DEF.widget_gap
    end
    return M.clamp_dp(v)
end

function M.grid_gutter_y_dp(merged_banner)
    local b = merged_banner or {}
    local v = tonumber(b.grid_gutter_y)
    if v == nil then
        v = tonumber(b.widget_gap) or DEF.widget_gap
    end
    return M.clamp_dp(v)
end

--- Full table consumed by LayoutSpec / composer (normalized banner dp fields).
function M.effective_dp(merged_banner)
    local b = merged_banner or {}
    local e = M.edge_margins_dp(b)
    local wg = M.widget_gap_dp(b)
    return {
        grid_edge_margin_left_dp = e.left_dp,
        grid_edge_margin_right_dp = e.right_dp,
        grid_edge_margin_top_dp = e.top_dp,
        grid_edge_margin_bottom_dp = e.bottom_dp,
        widget_gap_dp = wg,
        grid_gutter_x_dp = M.grid_gutter_x_dp(b),
        grid_gutter_y_dp = M.grid_gutter_y_dp(b),
        widget_padding_dp = tonumber(b.widget_padding) ~= nil and M.clamp_dp(b.widget_padding)
            or M.clamp_dp(DEF.widget_padding),
        widget_radius_dp = tonumber(b.widget_radius) ~= nil and M.clamp_dp(b.widget_radius)
            or M.clamp_dp(DEF.widget_radius),
    }
end

return M

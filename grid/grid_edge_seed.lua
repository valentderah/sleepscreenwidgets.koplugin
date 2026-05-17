--[[ One-off seed: materialize GridLayoutPhone square footprint as banner margins (spec 2026-05-16). ]]
local Config = require("config")
local BannerDp = require("grid.banner_dp")
local GridLayoutPhone = require("grid.grid_layout_phone")
local GridModel = require("grid.grid_model")

local M = {}

local inset_cap = assert(tonumber(Config.GRID_EDGE_INSET_MAX))
local LAYOUT = Config.GRID_LAYOUT

local function resolver_inner_pixel(B_SETT, screen_w, screen_h, inner_h_override, scale_by_size)
    local e = BannerDp.edge_margins_dp(B_SETT)
    local edge_ml = scale_by_size(e.left_dp)
    local edge_mr = scale_by_size(e.right_dp)
    local edge_mt = scale_by_size(e.top_dp)
    local edge_mb = scale_by_size(e.bottom_dp)
    local inner_w = math.max(LAYOUT.inner_min_px, screen_w - edge_ml - edge_mr)
    local inner_base_h = inner_h_override or screen_h
    local inner_h = math.max(LAYOUT.inner_min_px, inner_base_h - edge_mt - edge_mb)
    return inner_w, inner_h, edge_ml, edge_mr
end

local function gutter_px(B_SETT, scale_by_size)
    local gx = BannerDp.grid_gutter_x_dp(B_SETT)
    local gy = BannerDp.grid_gutter_y_dp(B_SETT)
    return scale_by_size(gx), scale_by_size(gy)
end

--- @param total_px integer desired sum of BOTH opposite margins in px (e.g. left+right).
--- @return integer|nil n such that approx 2*scale(n) ≈ total_px, or nil if no acceptable n (error > ALLOW_ERR_PX total).
local ALLOW_ERR_TOTAL_PX = 4 -- ~2 px per edge worst case across both sides combined

local function invert_symmetric_margin_dp(total_px, scale_by_size)
    total_px = math.floor(total_px + 0.5)
    if total_px <= 0 then
        return 0
    end
    local best_n, best_err = 0, math.huge
    for n = 0, inset_cap do
        local err = math.abs(2 * scale_by_size(n) - total_px)
        if err < best_err then
            best_err = err
            best_n = n
        end
    end
    if best_err > ALLOW_ERR_TOTAL_PX then
        return nil
    end
    return best_n
end

--- @param banner table merged DEFAULT_BANNER + saved overrides (caller builds).
--- @param screen_w integer
--- @param screen_h integer
--- @param grid_inner_h integer|nil same semantics as compose ctx.grid_inner_h; pass nil to use screen_h.
--- @param scale_by_size function(n) KOReader-compatible
--- @return table `{ ok=false, reason=string } | { ok=true, grid_edge_margin_x=integer, grid_edge_margin_y=integer }`
function M.seed_margins(opts)
    local banner = opts.banner or {}
    local screen_w = assert(tonumber(opts.screen_w))
    local screen_h = assert(tonumber(opts.screen_h))
    local grid_inner_h = opts.grid_inner_h
    local scale_by_size = assert(opts.scale_by_size)

    local inner_w_old, inner_h_old = resolver_inner_pixel(
        banner,
        screen_w,
        screen_h,
        grid_inner_h,
        scale_by_size
    )
    local gutter_x, gutter_y = gutter_px(banner, scale_by_size)
    local cols = GridModel.GRID_COLS
    local rows = GridModel.GRID_ROWS

    local sq_w, sq_h = GridLayoutPhone.slot_and_padding(
        inner_w_old,
        inner_h_old,
        cols,
        rows,
        gutter_x,
        gutter_y
    )

    if sq_w ~= sq_h then
        return { ok = false, reason = "non_square_cells" }
    end
    local s = sq_w
    if s < 1 then
        return { ok = false, reason = "bad_cell_side" }
    end

    local footprint_w = cols * s + (cols - 1) * gutter_x
    local footprint_h = rows * s + (rows - 1) * gutter_y
    local dw = math.floor(screen_w - footprint_w)
    local dh = math.floor(screen_h - footprint_h)
    if dw < 0 or dh < 0 then
        return { ok = false, reason = "footprint_overflow" }
    end

    local nx = invert_symmetric_margin_dp(dw, scale_by_size)
    local ny = invert_symmetric_margin_dp(dh, scale_by_size)
    if nx == nil or ny == nil then
        return { ok = false, reason = "inverse_margin_overflow" }
    end

    if nx > inset_cap or ny > inset_cap then
        return { ok = false, reason = "inset_over_cap" }
    end

    return {
        ok = true,
        grid_edge_margin_x = nx,
        grid_edge_margin_y = ny,
    }
end

--- Remove persisted keys no longer read by composer (migration + defensive writes).
function M.strip_deprecated_banner_keys_inplace(tbl)
    if type(tbl) == "table" then
        tbl.grid_phone_square = nil
    end
end

return M

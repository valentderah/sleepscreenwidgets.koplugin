-- Run from repo root: lua tests/grid_edge_seed_test.lua
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local function assert_near(a, b, tol, m)
    if math.abs(a - b) > tol then
        error((m or "near") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local Config = assert(require("config"))
local Seed = assert(require("grid.grid_edge_seed"))
local LayoutSpec = assert(require("grid.layout_spec"))
local GridModel = assert(require("grid.grid_model"))

local function linear_scale(k)
    return function(n)
        return math.floor(tonumber(n) * k + 0.5)
    end
end

local function default_banner_clone()
    local B = {}
    for key, val in pairs(Config.DEFAULT_BANNER) do
        B[key] = val
    end
    return B
end

-- Case A: scale 1:1 logical ↔ px — после сидирования доступная область должна давать квадратную ячейку
local banner_a = default_banner_clone()
local sw, sh = 800, 1400
local scale_a = linear_scale(1)

local seed_a = Seed.seed_margins({
    banner = banner_a,
    screen_w = sw,
    screen_h = sh,
    grid_inner_h = sh,
    scale_by_size = scale_a,
})
assert_eq(seed_a.ok, true, "case A seed ok")

local nx = seed_a.grid_edge_margin_x
local inner_w_chk = math.max(Config.GRID_LAYOUT.inner_min_px, sw - scale_a(nx) * 2)
local inner_h_chk = math.max(Config.GRID_LAYOUT.inner_min_px, sh - scale_a(seed_a.grid_edge_margin_y) * 2)
local gutx = scale_a(Config.DEFAULT_BANNER.widget_gap)

local slot_w_chk, row_h_chk = LayoutSpec.slot_and_row_height(
    inner_w_chk,
    inner_h_chk,
    GridModel.GRID_COLS,
    GridModel.GRID_ROWS,
    gutx,
    gutx
)
assert_eq(slot_w_chk, row_h_chk, "after seed square unit cell")
local footprint_w_chk = GridModel.GRID_COLS * slot_w_chk + (GridModel.GRID_COLS - 1) * gutx
local row_slack_allow = GridModel.GRID_COLS * 5
assert_near(
    footprint_w_chk,
    inner_w_chk,
    row_slack_allow,
    "classic row width vs inner (floor slack from GridGeometry)"
)

-- Case B: невозможно подобрать margin в px при scaleBySize(...) ≡ 0 (ошибка инвертора)
local banner_b = default_banner_clone()
local seed_b = Seed.seed_margins({
    banner = banner_b,
    screen_w = sw,
    screen_h = sh,
    grid_inner_h = sh,
    scale_by_size = function()
        return 0
    end,
})
assert_eq(seed_b.ok, false, "zero scale margins cannot invert")
assert_eq(seed_b.reason, "inverse_margin_overflow", "expected invert failure reason")

local strip_me = { grid_phone_square = true }
Seed.strip_deprecated_banner_keys_inplace(strip_me)
assert_eq(strip_me.grid_phone_square, nil, "strip flag")

print("grid_edge_seed_test: OK")

-- Run from repo root: lua tests/layout_spec_test.lua
package.path = package.path .. ";./?.lua"

local function shallow_copy(t)
    local u = {}
    for k, v in pairs(t) do
        u[k] = v
    end
    return u
end

local LS = assert(require("grid.layout_spec"))
local BD = assert(require("grid.banner_dp"))
local Config = assert(require("config"))

local merged = shallow_copy(Config.DEFAULT_BANNER)
merged.grid_edge_margin_x = 0
merged.grid_edge_margin_y = 0

local spec = LS.compute({
    screen_w = 600,
    screen_h = 800,
    grid_inner_h = 800,
    scale_by_size = function(n)
        return n
    end,
    banner_dp = BD.effective_dp(merged),
})

assert(spec.slot_w_px > 0, "slot_w_px")
assert(spec.row_h_px > 0, "row_h_px")
assert(spec.inner_w_px <= 600, "inner_w_px")

print("layout_spec_test basic: OK")

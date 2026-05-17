-- Run from repo root: lua tests/banner_dp_test.lua
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local BD = assert(require("grid.banner_dp"))

local eff = BD.effective_dp({ widget_gap = 5 })
assert_eq(eff.grid_gutter_x_dp, 5, "gutter x falls back to widget_gap")

local eff2 = BD.effective_dp({ grid_edge_margin_x = 10 })
assert_eq(eff2.grid_edge_margin_left_dp, 10, "symmetric x maps to left")

local eff_sym = BD.effective_dp({ grid_edge_margin = 8 })
assert_eq(eff_sym.grid_edge_margin_left_dp, 8, "left")
assert_eq(eff_sym.grid_edge_margin_right_dp, 8, "right")
assert_eq(eff_sym.grid_edge_margin_top_dp, 8, "top")
assert_eq(eff_sym.grid_edge_margin_bottom_dp, 8, "bottom")

local sym = BD.symm_edge_x_dp({ grid_edge_margin = 8 })
assert_eq(sym, 8, "symm_edge_x")

print("banner_dp_test: OK")

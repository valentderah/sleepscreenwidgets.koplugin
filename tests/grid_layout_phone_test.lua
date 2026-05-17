-- Run from repo root: lua tests/grid_layout_phone_test.lua
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local GP = assert(require("grid.grid_layout_phone"))
local LS = assert(require("grid.layout_spec"))

local inner_w = 420
local inner_h = 900
local cols, rows = 3, 6
local gx, gy = 8, 6

local sq_w, sq_h, px, py = GP.slot_and_padding(inner_w, inner_h, cols, rows, gx, gy)

assert_eq(sq_w, sq_h, "square sides")
local used_w = cols * sq_w + (cols - 1) * gx
local used_h = rows * sq_h + (rows - 1) * gy
assert_eq(px * 2 + used_w <= inner_w, true, "fits width")
assert_eq(py * 2 + used_h <= inner_h, true, "fits height")

local sw_plain, rh_plain = LS.slot_and_row_height(inner_w, inner_h, cols, rows, gx, gy)
assert_eq(sw_plain <= sq_w + 2, true, "square not oversized vs classic width slot")

print("grid_layout_phone_test: OK")

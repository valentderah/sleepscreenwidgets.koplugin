-- Run from repo root: lua tests/battery_ring_layout_test.lua
package.path = package.path .. ";./?.lua"

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local BL = assert(require("banner.widgets.battery.battery_ring_layout"))

local inset48 = BL.ring_left_inset(48)
assert_true(inset48 >= 0 and inset48 < 24, "ring_left_inset(48) sane")

local inset96 = BL.ring_left_inset(96)
assert_true(inset96 >= inset48, "larger S should not decrease inset unexpectedly")

local S = BL.battery_ring_square_side(200, 120, 6, 40)
assert_true(S <= 200 and S <= 120 - 6 - 40 + 1, "S respects reserves")

local S2 = BL.battery_ring_square_side(80, 300, 4, 30)
assert_true(S2 <= 80, "width cap")

local S3 = BL.ring_square_side_fit(100, 72, 6, 26, 8)
assert_true(S3 <= 72 - 6 - 26 - 8 + 1 and S3 >= 20, "ring_square_side_fit vertical budget")

local Sfill = BL.ring_side_vertical_fill(100, 120, 6, 24, 6)
assert_true(Sfill <= 100 and Sfill <= 120 - 6 - 24 - 6 + 1 and Sfill >= 20, "ring_side_vertical_fill budget")

print("battery_ring_layout_test: OK")

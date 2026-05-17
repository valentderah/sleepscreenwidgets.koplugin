-- Run from repo root: lua tests/grid_geometry_test.lua
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "assert_eq") .. ": got " .. tostring(a) .. " expected " .. tostring(b))
    end
end

local LS = assert(require("grid.layout_spec"))
local sw, rh = LS.slot_and_row_height(300, 600, 3, 6, 8, 6)
assert_eq(sw, math.floor((300 - 16) / 3))
assert_eq(rh, math.floor((600 - 5 * 6) / 6))
assert_eq(LS.merged_span_width(sw, 8, 2), 2 * sw + 8)
assert_eq(LS.merged_span_width(sw, 8, 3), 3 * sw + 16)
print("grid_geometry_test: OK")

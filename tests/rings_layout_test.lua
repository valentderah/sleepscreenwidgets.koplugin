-- Run from repo root: lua tests/rings_layout_test.lua
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local RL = assert(require("banner.widgets.activity.rings_layout"))

assert_eq(RL.progress_draw_frac(30, 60), 0.5)
assert_eq(RL.progress_draw_frac(120, 60), 1)
assert_eq(RL.progress_draw_frac(0, 60), 0)
assert_eq(RL.progress_draw_frac(5, 0), 0, "goal zero")

do
    local st, _gap, ro, ri, cx, cy = RL.ring_geometry(180, true)
    assert(type(ro) == "number", "r_outer number")
    assert_eq(cx, 180 / 2)
    assert_eq(cy, 180 / 2)
    assert(ri < ro, "inner < outer")
    assert(st >= 4, "stroke>=4 dual")
end

do
    local st, _gap, r1, _ri, _cx, _cy = RL.ring_geometry(180, false)
    assert(r1 > 0, "single ring radius")
    assert(st >= 4, "stroke>=4 single")
end

do
    -- max_h=200, reserve 90 -> capped to floor(200*0.38)=76, avail 124, generous min(400,200)*0.9=180
    local side = RL.rings_square_side(400, 200, 90)
    assert_eq(side, 124)
end

do
    -- Short cell: reserve would over-shrink without cap; expect most of height left for rings.
    local side = RL.rings_square_side(120, 88, 76)
    assert(side >= 50, "short slot still gets usable ring")
    assert(side <= 88, "fits cell")
end

print("rings_layout_test: OK")

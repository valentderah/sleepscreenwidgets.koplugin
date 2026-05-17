-- Run from repo root: lua tests/grid_model_test.lua
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local GM = assert(require("grid.grid_model"))
local Config = assert(require("config"))

local function mock_default(t)
    if t == "wide" then
        return 3
    end
    return 1
end

local function def1(_)
    return 1
end

-- Only grid_version 3 blobs are accepted
local legacy = { grid_version = 2, placements = {} }
local p = GM.parseSaved(legacy, def1)
assert_eq(#p, 0)
local weird = { foo = 1 }
local pw = GM.parseSaved(weird, def1)
assert_eq(#pw, 0)
print("grid_model_test non-v3 parseSaved: OK")

-- dedupe: two at same anchor
local dup = {
    { type = "clock", params = {}, row = 1, col = 1 },
    { type = "battery", params = {}, row = 1, col = 1 },
}
local p2 = GM.normalizePlacements(dup, def1)
assert_eq(#p2, 1)
assert_eq(p2[1].type, "clock")
print("grid_model_test dedupe: OK")

-- wide default span 3 occupies row 1; second widget dropped
local wide = {
    { type = "wide", params = {}, row = 1, col = 1 },
    { type = "clock", params = {}, row = 1, col = 2 },
}
local p3 = GM.normalizePlacements(wide, mock_default)
assert_eq(#p3, 1)
assert_eq(p3[1].type, "wide")
assert_eq(GM.resolveColSpan(p3[1].type, p3[1].params, p3[1].row, p3[1].col, mock_default), 3)
print("grid_model_test wide span: OK")

local function registry_like_span(t)
    if t == "datetime" then
        return 3
    end
    if t == "activity" then
        return 3
    end
    return 1
end

local defp = GM.normalizePlacements(Config.DEFAULT_GRID_PLACEMENTS, registry_like_span)
assert_eq(#defp, 5)
assert_eq(defp[1].type, "datetime")
assert_eq(defp[2].type, "reading_now")
assert_eq(defp[3].type, "highlight")
assert_eq(defp[4].type, "calendar")
assert_eq(defp[5].type, "activity")
print("grid_model_test default grid: OK")

local v3 = { grid_version = 3, placements = {
    { type = "clock", params = { variant = "digital" }, row = 1, col = 1 },
}}
local pv3 = GM.parseSaved(v3, def1)
assert_eq(#pv3, 1)
assert_eq(pv3[1].type, "clock")
local wrapped = GM.wrapSaved({ { type = "template", params = {}, row = 2, col = 1 } })
assert_eq(wrapped.grid_version, 3)
print("grid_model_test v3 wrap/parse: OK")

local occ = GM.occupancy_flags(p3, mock_default)
assert_eq(occ[1][1], true)
assert_eq(occ[1][2], true)
assert_eq(occ[1][3], true)
print("grid_model_test occupancy: OK")

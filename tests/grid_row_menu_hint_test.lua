package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": got " .. tostring(a) .. " expected " .. tostring(b))
    end
end

local H = assert(require("grid.row_menu_hint"))
local GM = require("grid.grid_model")

local function def1(_) return 1 end
local function def_wide(t)
    if t == "datetime" then return 3 end
    return 1
end

local wide = {
    { type = "datetime", params = {}, row = 1, col = 1 },
}
local pwide = GM.normalizePlacements(wide, def_wide)
assert_eq(H.row_hint(pwide, 1, def_wide), "datetime · · · ·")

local mix = {
    { type = "clock", params = {}, row = 2, col = 1 },
    { type = "battery", params = {}, row = 2, col = 3 },
}
assert_eq(H.row_hint(mix, 2, def1), "clock · — · battery")

assert_eq(H.cell_token({}, 1, 1, def1), "—")
print("grid_row_menu_hint_test: OK")

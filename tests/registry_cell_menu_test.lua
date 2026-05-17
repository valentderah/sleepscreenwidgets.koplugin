-- Run from repo root: lua tests/registry_cell_menu_test.lua
package.path = package.path .. ";./?.lua"
package.loaded["logger"] = { warn = function() end }

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local R = assert(require("banner.widgets.registry"))

R.register("_x", function() end, {})
assert_eq(#R.cell_menu_items("_x", {}), 0, "no cell_menu")

R.register("_y", function() end, {
    cell_menu = function()
        return { { text = "one" } }
    end,
})
assert_eq(#R.cell_menu_items("_y", {}), 1)

print("registry_cell_menu_test: OK")

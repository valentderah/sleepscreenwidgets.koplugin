-- Run from repo root: lua tests/registry_widget_contract_test.lua
-- Loads widget register modules only (no Build / KOReader UI).
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local order = {
    "template",
    "highlight",
    "clock",
    "datetime",
    "battery",
    "reading_now",
    "activity",
    "calendar",
}

for _, id in ipairs(order) do
    local mod = assert(require("banner.widgets." .. id .. ".register"))
    local st = mod.WIDGET_REGISTER_STATIC
    assert(type(st) == "table", id .. ": WIDGET_REGISTER_STATIC missing")
    assert_eq(type(st.default_params), "table", id .. ".default_params")
    assert_eq(type(st.param_fields), "table", id .. ".param_fields")
    local menu = st.default_params.menu
    if type(menu) == "table" and type(menu.expose) == "table" then
        for key, on in pairs(menu.expose) do
            if on == true and st.param_fields[key] == nil then
                error(id .. ": exposed key missing in param_fields: " .. tostring(key))
            end
        end
    end
end

print("registry_widget_contract_test: OK")

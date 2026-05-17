-- Run from repo root: lua tests/registry_meta_api_test.lua
package.path = package.path .. ";./?.lua"
package.loaded["logger"] = { warn = function() end }

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local Reg = assert(require("banner.widgets.registry"))

Reg.__test_reset()

local noop = function() end
Reg.register("unit", noop, {
    default_params = {
        a = 1,
        menu = {
            expose = { daily_goal_minutes = true },
            order = { "daily_goal_minutes" },
        },
    },
    param_fields = {
        daily_goal_minutes = { kind = "number" },
    },
})

assert_eq(Reg.default_params("unit").a, 1)
assert_eq(Reg.param_fields("unit").daily_goal_minutes.kind, "number")

local merged = Reg.normalize_widget_params("unit", { a = 2 })
assert_eq(merged.a, 2)
assert_eq(type(merged.menu), "table")
assert_eq(merged.menu.expose.daily_goal_minutes, true)

Reg.__test_reset()
Reg.register("empty", noop, {})
assert_eq(next(Reg.default_params("empty")) == nil, true, "empty default_params")

print("registry_meta_api_test: OK")

-- Run from repo root: lua tests/goal_journal_math_test.lua
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local JM = assert(require("banner.widgets.activity.journal_math"))

assert_eq(JM.iso_prev_day("2024-03-01"), "2024-02-29", "prev day leap")
assert_eq(JM.iso_prev_day("2024-03-05"), "2024-03-04", "prev day normal")

local days = {}
days["2026-05-14"] = true
days["2026-05-15"] = true
days["2026-05-16"] = true
assert_eq(JM.streak_from_daily_map(days, "2026-05-16"), 3, "three day streak")

assert_eq(JM.targets_met_today(30, 5, 30, 0), true)
assert_eq(JM.targets_met_today(29, 5, 30, 0), false)
assert_eq(JM.targets_met_today(60, 0, 60, 0), true)

local map = {
    ["2009-06-06"] = true,
    ["2031-01-02"] = true,
    ["2031-01-01"] = true,
    ["2030-12-31"] = true,
    ["2030-12-30"] = true,
    ["2030-12-29"] = true,
    ["2030-12-28"] = false,
}

JM.prune_daily_map(map, "2031-01-02", 3)

assert(map["2009-06-06"] == nil, "old prune")
assert(map["2030-12-30"] == nil, "beyond window")
assert_eq(map["2031-01-02"], true)
assert_eq(map["2031-01-01"], true)
assert_eq(map["2030-12-31"], true)

print("goal_journal_math_test: OK")

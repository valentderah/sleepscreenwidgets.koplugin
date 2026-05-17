-- Run from repo root: lua tests/week_window_test.lua
package.path = package.path .. ";./?.lua"

local WW = assert(require("data.week_window"))

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local now = { year = 2026, month = 5, day = 18, wday = 2, isdst = false }

local d_mon = WW.seven_days(now, "mon")
assert_eq(#d_mon, 7, "len mon")
assert_eq(d_mon[1].year, 2026, "mon anchor y")
assert_eq(d_mon[1].month, 5, "mon anchor m")
assert_eq(d_mon[1].day, 18, "mon anchor d")
assert_eq(d_mon[7].day, 24, "mon last d")

local d_sun = WW.seven_days(now, "sun")
assert_eq(d_sun[1].day, 17, "sun anchor Sun May 17")
assert_eq(d_sun[2].day, 18, "sun col2 Mon")
assert_eq(WW.index_of_today(d_sun, 2026, 5, 18), 2, "today idx sun window")

print("week_window_test: OK")

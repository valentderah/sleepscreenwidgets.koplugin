package.path = package.path .. ";./?.lua"
local WB = assert(require("data.week_bounds"))

local tues = os.time({ year = 2026, month = 5, day = 19, hour = 14, min = 30, sec = 0 })
local mon = WB.monday_midnight_unix_before_or_equal(tues)
local dm = os.date("*t", mon)
assert(dm.year == 2026 and dm.month == 5 and dm.day == 18)
assert(dm.hour == 0 and dm.min == 0 and dm.sec == 0)

local mon_mid = WB.monday_midnight_unix_before_or_equal(mon)
assert(mon_mid == mon, "Monday midnight is fixed point")

local sun = os.time({ year = 2026, month = 5, day = 24, hour = 20, min = 0, sec = 0 })
local before = WB.monday_midnight_unix_before_or_equal(sun)
local ds = os.date("*t", before)
assert(ds.wday == 2, "expected Monday anchor for Lua wday numbering")

print("week_bounds_test: OK")

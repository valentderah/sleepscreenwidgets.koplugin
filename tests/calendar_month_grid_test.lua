-- Run from repo root: lua tests/calendar_month_grid_test.lua
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local MG = assert(require("banner.widgets.calendar.month_grid"))

-- Monday-first (default product behaviour): June 2026 starts Monday → day 1 in column 1.
local g_mon = MG.cell_grid(2026, 6, 2026, 6, 7, "mon")
assert_eq(g_mon[1][1].day, 1, "June 2026 Mon-first: 1st in col 1")

-- Sunday-first: June 2026 → column 1 empty, Monday 1st in column 2.
local g_sun = MG.cell_grid(2026, 6, 2026, 6, 7, "sun")
assert_eq(g_sun[1][1].day, nil, "June 2026 Sun-first: leading Sun column empty")
assert_eq(g_sun[1][2].day, 1, "June 2026 Sun-first: Monday 1st in col 2")

assert_eq(MG.days_in_month(2025, 2), 28, "Feb 2025")
assert_eq(MG.days_in_month(2024, 2), 29, "Feb 2024 leap")

local g2 = MG.cell_grid(2024, 2, 2024, 2, 29, "mon")
assert_eq(g2[6][7].day, nil, "Leap Feb does not spill past last day")
local found29 = false
for r = 1, 6 do
    for c = 1, 7 do
        local cell = g2[r][c]
        if cell.day == 29 then
            assert_eq(cell.is_today, true, "today marker on 29")
            found29 = true
        end
    end
end
assert_eq(found29, true, "Feb 2024 has day 29 somewhere")

local g3 = MG.cell_grid(2026, 6, 2026, 6, 1, "mon")
assert_eq(g3[1][1].is_today, true, "June 1 2026 Mon-first today in col 1")

print("calendar_month_grid_test: OK")

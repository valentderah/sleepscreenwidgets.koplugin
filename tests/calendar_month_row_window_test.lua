-- Run from repo root: lua tests/calendar_month_row_window_test.lua
package.path = package.path .. ";./?.lua"

local function assert_eq(a, b, m)
    if a ~= b then
        error((m or "eq") .. ": " .. tostring(a) .. " vs " .. tostring(b))
    end
end

local W = assert(require("banner.widgets.calendar.month_row_window"))

assert_eq(W.visible_row_start(2, 5, 4, 3), 3, "center today row 4 -> 3..5")
assert_eq(W.visible_row_start(1, 6, 1, 3), 1, "today top clamp")
assert_eq(W.visible_row_start(1, 6, 6, 3), 4, "today bottom clamp -> 4..6")
assert_eq(W.visible_row_start(1, 5, 3, 5), 1, "k >= need_rows -> r_min")
assert_eq(W.visible_row_start(2, 5, nil, 3), 2, "no today -> r_min")
assert_eq(W.visible_row_start(3, 3, 3, 1), 3, "k=1 -> today row")

assert_eq(W.max_date_rows_fit(34, 10, 2), 3, "exact three rows")
assert_eq(W.max_date_rows_fit(33, 10, 2), 2, "one short -> two rows")
assert_eq(W.max_date_rows_fit(0, 10, 2), 1, "no height -> at least 1")

local g = {}
for r = 1, 6 do
    g[r] = {}
    for c = 1, 7 do
        g[r][c] = { day = nil, is_today = false }
    end
end
g[2][3].day = 1
g[5][7].day = 31
local mn, mx = W.occupied_row_range(g)
assert_eq(mn, 2, "r_min")
assert_eq(mx, 5, "r_max")

print("calendar_month_row_window_test: OK")

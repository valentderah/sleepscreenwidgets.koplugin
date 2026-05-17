-- Run from repo root: lua tests/calendar_month_date_fit_test.lua
package.path = package.path .. ";./?.lua"

local function assert_true(cond, msg)
    if not cond then
        error(msg or "assert_true failed")
    end
end

local MDF = assert(require("banner.widgets.calendar.month_date_fit"))

local ctx = { col_span = 1 }

do
    local sz, pad = MDF.pick_date_cell_sz_and_pad(48, ctx, function(n)
        return n
    end)
    assert_true(sz >= MDF.MIN_CELL_SZ and sz <= MDF.DEFAULT_START_CELL_SZ, "sz in range wide cell")
    assert_true(pad >= 2, "pad sane")
end

do
    local sz, pad = MDF.pick_date_cell_sz_and_pad(32, ctx, function(n)
        return n
    end)
    local inner = 32 - 2 * pad
    assert_true(MDF.estimated_day_pair_width_px(sz, ctx) <= inner - 2, "pair fits heuristic at cell_w=32")
    assert_true(sz >= MDF.MIN_CELL_SZ, "above floor")
end

print("calendar_month_date_fit_test: OK")

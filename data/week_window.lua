--[[ Local sliding window of 7 calendar days containing «today».
    week_start: "mon" | "sun" (anything else → "mon").
    DST: calendar math via noon os.time (same idea as data/week_bounds.lua). ]]
local M = {}

local function norm_ws(ws)
    if ws == "sun" then
        return "sun"
    end
    return "mon"
end

--- @param wday_lua integer os.date("*t").wday, 1=Sunday .. 7=Saturday
--- @param week_start "mon"|"sun"
--- @return integer days_back
local function days_back_to_anchor(wday_lua, week_start)
    if week_start == "sun" then
        return wday_lua - 1
    end
    return (wday_lua + 5) % 7
end

--- @param now table year, month, day, wday, isdst as from os.date("*t")
--- @param week_start string
--- @return table normalized midnight fields for first day of window
function M.anchor_midnight_fields(now, week_start)
    week_start = norm_ws(week_start)
    local w = math.floor(tonumber(now.wday) or 1)
    local back = days_back_to_anchor(w, week_start)
    local ts = os.time({
        year = now.year,
        month = now.month,
        day = now.day - back,
        hour = 12,
        min = 0,
        sec = 0,
        isdst = now.isdst,
    })
    local tt = os.date("*t", ts)
    return {
        year = tt.year,
        month = tt.month,
        day = tt.day,
        hour = 0,
        min = 0,
        sec = 0,
        isdst = tt.isdst,
    }
end

--- @return table[] seven entries { year, month, day, wday }
function M.seven_days(now, week_start)
    local af = M.anchor_midnight_fields(now, week_start)
    local out = {}
    for i = 0, 6 do
        local ts = os.time({
            year = af.year,
            month = af.month,
            day = af.day + i,
            hour = 12,
            min = 0,
            sec = 0,
            isdst = af.isdst,
        })
        local tt = os.date("*t", ts)
        table.insert(out, {
            year = tt.year,
            month = tt.month,
            day = tt.day,
            wday = tonumber(tt.wday) or 1,
        })
    end
    return out
end

function M.index_of_today(days, today_y, today_m, today_d)
    for i = 1, 7 do
        local d = days[i]
        if d.year == today_y and d.month == today_m and d.day == today_d then
            return i
        end
    end
    return nil
end

return M

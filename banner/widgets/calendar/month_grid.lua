--[[ Pure Lua: 6×7 calendar grid; first column Monday or Sunday via week_start. ]]
local M = {}

function M.days_in_month(year, month)
    year = math.floor(tonumber(year) or 0)
    month = math.floor(tonumber(month) or 0)
    local mdays = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if month == 2 then
        local leap = (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
        return leap and 29 or 28
    end
    if month < 1 or month > 12 then
        return 0
    end
    return mdays[month]
end

--- @param week_start "mon"|"sun" first column Monday or Sunday (default "mon").
--- @return table[6][7] each cell { day = nil|number, is_today = boolean }
function M.cell_grid(year, month, today_year, today_month, today_day, week_start)
    year = math.floor(tonumber(year) or 0)
    month = math.floor(tonumber(month) or 0)
    today_year = math.floor(tonumber(today_year) or 0)
    today_month = math.floor(tonumber(today_month) or 0)
    today_day = math.floor(tonumber(today_day) or 0)
    week_start = (week_start == "sun") and "sun" or "mon"

    local dim = M.days_in_month(year, month)
    local t0 = os.time({ year = year, month = month, day = 1, hour = 12, min = 0, sec = 0 })
    local d1 = os.date("*t", t0)
    local wstart = tonumber(d1.wday) or 1 -- Lua: 1 = Sunday .. 7 = Saturday

    --- 0-based column index for the 1st of month (col 0 = first weekday column).
    local col0
    if week_start == "sun" then
        col0 = wstart - 1
    else
        col0 = (wstart - 2 + 7) % 7
    end

    local grid = {}
    for r = 1, 6 do
        grid[r] = {}
        for c = 1, 7 do
            grid[r][c] = { day = nil, is_today = false }
        end
    end

    for day = 1, dim do
        local idx = col0 + (day - 1)
        local r = math.floor(idx / 7) + 1
        local c = idx % 7 + 1
        if r <= 6 then
            local cell = grid[r][c]
            cell.day = day
            cell.is_today = (year == today_year and month == today_month and day == today_day)
        end
    end

    return grid
end

return M

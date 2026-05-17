--[[ Pure Lua: какие строки 6×7 месяца показывать при ограничении по высоте (спека 2026-05-18). ]]
local M = {}

--- @param grid table[6][7] как из MonthGrid.cell_grid
--- @return integer r_min, integer r_max (1..6); если дат нет — 1, 1
function M.occupied_row_range(grid)
    local r_min, r_max = nil, nil
    for r = 1, 6 do
        local row = grid[r]
        if type(row) == "table" then
            for c = 1, 7 do
                local cell = row[c]
                if type(cell) == "table" and cell.day ~= nil then
                    r_min = r_min and math.min(r_min, r) or r
                    r_max = r_max and math.max(r_max, r) or r
                end
            end
        end
    end
    if not r_min then
        return 1, 1
    end
    return r_min, r_max
end

function M.today_row_index(grid)
    for r = 1, 6 do
        local row = grid[r]
        if type(row) == "table" then
            for c = 1, 7 do
                local cell = row[c]
                if type(cell) == "table" and cell.is_today then
                    return r
                end
            end
        end
    end
    return nil
end

--- k строк при высоте строк row_h и зазоре g_row между ними: k*row_h + (k-1)*g_row <= H_dates
function M.max_date_rows_fit(H_dates, row_h, g_row)
    H_dates = math.max(0, tonumber(H_dates) or 0)
    row_h = tonumber(row_h) or 0
    g_row = tonumber(g_row) or 0
    local denom = row_h + g_row
    if denom <= 0 then
        return 1
    end
    local k = math.floor((H_dates + g_row) / denom)
    return math.max(1, k)
end

--- Окно из k строк внутри [r_min,r_max], желательно с центром на r_today (спека §5).
function M.visible_row_start(r_min, r_max, r_today, k)
    r_min = math.floor(tonumber(r_min) or 1)
    r_max = math.floor(tonumber(r_max) or 1)
    k = math.floor(tonumber(k) or 1)
    if r_max < r_min then
        r_min, r_max = r_max, r_min
    end
    local need_rows = r_max - r_min + 1
    if k >= need_rows then
        return r_min
    end
    if r_today == nil or r_today < r_min or r_today > r_max then
        return r_min
    end
    local start = r_today - math.floor((k - 1) / 2)
    if start < r_min then
        start = r_min
    end
    if start + k - 1 > r_max then
        start = r_max - k + 1
    end
    return start
end

return M

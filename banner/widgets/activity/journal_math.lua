--[[ Pure helpers for goal streak / daily journal (testable without KOReader FFI).]]
local M = {}

function M.has_active_goal(goal_minutes, goal_pages)
    local gm = math.max(0, math.floor(tonumber(goal_minutes) or 0))
    local gp = math.max(0, math.floor(tonumber(goal_pages) or 0))
    return gm > 0 or gp > 0
end

function M.targets_met_today(read_minutes, read_pages, goal_minutes, goal_pages)
    local gm = math.max(0, math.floor(tonumber(goal_minutes) or 0))
    local gp = math.max(0, math.floor(tonumber(goal_pages) or 0))
    if gm > 0 and (tonumber(read_minutes) or 0) < gm then
        return false
    end
    if gp > 0 and (tonumber(read_pages) or 0) < gp then
        return false
    end
    return gm > 0 or gp > 0
end

function M.today_iso()
    local t = os.date("*t")
    return string.format("%04d-%02d-%02d", t.year, t.month, t.day)
end

function M.iso_prev_day(iso_date)
    if type(iso_date) ~= "string" then
        return nil
    end
    local y, mo, d = iso_date:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    y, mo, d = tonumber(y), tonumber(mo), tonumber(d)
    if not y or not mo or not d then
        return nil
    end
    local tstamp = os.time({ year = y, month = mo, day = d, hour = 12 })
    tstamp = tstamp - 86400
    local nt = os.date("*t", tstamp)
    return string.format("%04d-%02d-%02d", nt.year, nt.month, nt.day)
end

function M.streak_from_daily_map(days, today_iso)
    if type(days) ~= "table" or type(today_iso) ~= "string" then
        return 0
    end
    local iso = today_iso
    local n = 0
    local guard = 370
    for _ = 1, guard do
        if days[iso] ~= true then
            break
        end
        n = n + 1
        local prev = M.iso_prev_day(iso)
        if not prev then
            break
        end
        iso = prev
    end
    return n
end

function M.prune_daily_map(days, today_iso, keep_days)
    if type(days) ~= "table" or type(today_iso) ~= "string" then
        return
    end
    local k = math.max(1, math.floor(tonumber(keep_days) or 400))
    local allowed = {}
    local iso = today_iso
    for _ = 1, k do
        allowed[iso] = true
        local prev = M.iso_prev_day(iso)
        if not prev then
            break
        end
        iso = prev
    end
    for key in pairs(days) do
        if allowed[key] ~= true then
            days[key] = nil
        end
    end
end

return M

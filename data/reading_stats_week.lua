--[[ Per-weekday totals (Monday..Sunday) using page_stat.duration sums.
Week anchor: Monday 00:00 local (data.week_bounds).
DST: naive window week_start .. week_start + 7*86400 exclusive.]]
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local week_bounds = require("data.week_bounds")

local M = {}

--- SQLite strftime('%%w', …, 'localtime'): 0 Sunday .. 6 Saturday. Bucket: Monday=1 .. Sunday=7.
local function sqlite_wday_to_bucket(dow)
    dow = tonumber(dow)
    if dow == nil then
        return nil
    end
    if dow == 0 then
        return 7
    end
    return dow
end

local function empty_week()
    return { 0, 0, 0, 0, 0, 0, 0 }
end

function M.seconds_per_weekday_since_monday()
    local path = require("datastorage"):getSettingsDir() .. "/statistics.sqlite3"
    if lfs.attributes(path, "mode") ~= "file" then
        return nil, "no_db"
    end

    local now = os.time()
    local week_start = math.floor(tonumber(week_bounds.monday_midnight_unix_before_or_equal(now)) or now)
    local week_end = week_start + 7 * 86400

    local ok_sq, SQ3 = pcall(require, "lua-ljsqlite3/init")
    if not ok_sq or not SQ3 then
        return nil, "no_sqlite"
    end

    local ok_open, conn = pcall(SQ3.open, path)
    if not ok_open or not conn then
        return nil, "open_failed"
    end

    local sql = string.format(
        [[SELECT strftime('%%w', start_time, 'unixepoch', 'localtime'), COALESCE(SUM(duration), 0)
FROM page_stat
WHERE start_time >= %d AND start_time < %d
GROUP BY 1]],
        week_start,
        week_end
    )

    local totals = empty_week()
    local stmt = conn:prepare(sql)
    if not stmt then
        pcall(function()
            conn:close()
        end)
        logger.warn("sleepscreenwidgets", "reading_stats_week: prepare failed")
        return nil, "query_failed"
    end

    local ok_q, outerr = pcall(function()
        local res, nb = stmt:reset():resultset("i")
        if type(res) ~= "table" then
            return
        end
        nb = tonumber(nb) or 0
        for i = 1, nb do
            local dow_raw = res[1][i]
            local sumd = tonumber(res[2][i]) or 0
            if sumd < 0 then
                sumd = 0
            end
            local bucket = sqlite_wday_to_bucket(dow_raw)
            if bucket then
                totals[bucket] = totals[bucket] + math.floor(sumd)
            end
        end
    end)

    pcall(function()
        stmt:close()
    end)

    pcall(function()
        conn:close()
    end)

    if not ok_q then
        logger.warn("sleepscreenwidgets", "reading_stats_week: " .. tostring(outerr))
        return nil, "query_failed"
    end

    return totals, nil
end

--- Sum duration per local calendar day (YYYY-MM-DD) in [start_unix, end_unix).
--- @return table|nil map date_str -> seconds integer
--- @return string|nil err
function M.seconds_sum_by_local_date(start_unix, end_unix)
    start_unix = math.floor(tonumber(start_unix) or 0)
    end_unix = math.floor(tonumber(end_unix) or 0)
    if end_unix <= start_unix then
        return {}
    end

    local path = require("datastorage"):getSettingsDir() .. "/statistics.sqlite3"
    if lfs.attributes(path, "mode") ~= "file" then
        return nil, "no_db"
    end

    local ok_sq, SQ3 = pcall(require, "lua-ljsqlite3/init")
    if not ok_sq or not SQ3 then
        return nil, "no_sqlite"
    end

    local ok_open, conn = pcall(SQ3.open, path)
    if not ok_open or not conn then
        return nil, "open_failed"
    end

    local sql = string.format(
        [[SELECT strftime('%%Y-%%m-%%d', start_time, 'unixepoch', 'localtime'), COALESCE(SUM(duration), 0)
FROM page_stat
WHERE start_time >= %d AND start_time < %d
GROUP BY 1]],
        start_unix,
        end_unix
    )

    local map = {}
    local stmt = conn:prepare(sql)
    if not stmt then
        pcall(function()
            conn:close()
        end)
        logger.warn("sleepscreenwidgets", "reading_stats_week: seconds_sum prepare failed")
        return nil, "query_failed"
    end

    local ok_q, outerr = pcall(function()
        local res, nb = stmt:reset():resultset("i")
        if type(res) ~= "table" then
            return
        end
        nb = tonumber(nb) or 0
        for i = 1, nb do
            local key = res[1][i]
            local sv = math.max(0, math.floor(tonumber(res[2][i]) or 0))
            if type(key) == "string" and key ~= "" then
                map[key] = sv
            end
        end
    end)

    pcall(function()
        stmt:close()
    end)
    pcall(function()
        conn:close()
    end)

    if not ok_q then
        logger.warn("sleepscreenwidgets", "reading_stats_week: " .. tostring(outerr))
        return nil, "query_failed"
    end

    return map, nil
end

--- Distinct pages per local calendar day (same rule as today: DISTINCT id_book, page).
--- @return table|nil map date_str -> count integer
--- @return string|nil err
function M.pages_sum_by_local_date(start_unix, end_unix)
    start_unix = math.floor(tonumber(start_unix) or 0)
    end_unix = math.floor(tonumber(end_unix) or 0)
    if end_unix <= start_unix then
        return {}
    end

    local path = require("datastorage"):getSettingsDir() .. "/statistics.sqlite3"
    if lfs.attributes(path, "mode") ~= "file" then
        return nil, "no_db"
    end

    local ok_sq, SQ3 = pcall(require, "lua-ljsqlite3/init")
    if not ok_sq or not SQ3 then
        return nil, "no_sqlite"
    end

    local ok_open, conn = pcall(SQ3.open, path)
    if not ok_open or not conn then
        return nil, "open_failed"
    end

    local sql = string.format(
        [[SELECT sub.d, COUNT(*) FROM (
  SELECT strftime('%%Y-%%m-%%d', start_time, 'unixepoch', 'localtime') AS d,
         id_book, page
  FROM page_stat
  WHERE start_time >= %d AND start_time < %d
  GROUP BY 1, id_book, page
) AS sub
GROUP BY sub.d]],
        start_unix,
        end_unix
    )

    local map = {}
    local stmt = conn:prepare(sql)
    if not stmt then
        pcall(function()
            conn:close()
        end)
        logger.warn("sleepscreenwidgets", "reading_stats_week: pages_sum prepare failed")
        return nil, "query_failed"
    end

    local ok_q, outerr = pcall(function()
        local res, nb = stmt:reset():resultset("i")
        if type(res) ~= "table" then
            return
        end
        nb = tonumber(nb) or 0
        for i = 1, nb do
            local key = res[1][i]
            local sv = math.max(0, math.floor(tonumber(res[2][i]) or 0))
            if type(key) == "string" and key ~= "" then
                map[key] = sv
            end
        end
    end)

    pcall(function()
        stmt:close()
    end)
    pcall(function()
        conn:close()
    end)

    if not ok_q then
        logger.warn("sleepscreenwidgets", "reading_stats_week: " .. tostring(outerr))
        return nil, "query_failed"
    end

    return map, nil
end

return M

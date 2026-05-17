local lfs = require("libs/libkoreader-lfs")
local day_bounds = require("data.day_bounds")
local logger = require("logger")

-- Schema/source: KOReader upstream plugins/statistics.koplugin/main.lua —
-- persistent table `page_stat_data` has id_book, page, start_time, duration, …;
-- query surface is VIEW `page_stat` with columns id_book, page, start_time, duration.
-- DISTINCT (id_book, page): several sessions on the same page today count once
-- for a «pages» goal (not COUNT(*) row events).

local M = {}

function M._sql_fragment_for_pages_since(since_ts)
    since_ts = math.floor(tonumber(since_ts) or 0)
    -- SQLite has no COUNT(DISTINCT tuple); DISTINCT id_book, page in a subquery.
    return string.format(
        "SELECT COUNT(*) FROM (SELECT DISTINCT id_book, page FROM page_stat WHERE start_time >= %d)",
        since_ts
    )
end

function M.pages_read_today()
    local path = require("datastorage"):getSettingsDir() .. "/statistics.sqlite3"
    if lfs.attributes(path, "mode") ~= "file" then
        return nil, "no_db"
    end

    local since = day_bounds.local_midnight_before_or_at()

    local ok_sq, SQ3 = pcall(require, "lua-ljsqlite3/init")
    if not ok_sq or not SQ3 then
        return nil, "no_sqlite"
    end

    local ok_open, conn = pcall(SQ3.open, path)
    if not ok_open or not conn then
        return nil, "open_failed"
    end

    local sql = M._sql_fragment_for_pages_since(math.floor(tonumber(since) or 0))

    local ok_q, cnt = pcall(function()
        return conn:rowexec(sql)
    end)

    pcall(function()
        conn:close()
    end)

    if not ok_q then
        logger.warn("sleepscreenwidgets", "reading_stats_pages_today: query failed")
        return nil, "query_failed"
    end

    local n = math.max(0, tonumber(cnt) or 0)
    return n, nil
end

return M

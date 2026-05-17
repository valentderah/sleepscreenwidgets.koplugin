--[[ Single entry for widgets that need reading statistics (spec §A.4). ]]
local reading_stats_day = require("data.reading_stats_day")
local reading_stats_pages_today = require("data.reading_stats_pages_today")
local reading_stats_week = require("data.reading_stats_week")

local M = {}

function M.total_seconds_today()
    return reading_stats_day.total_seconds_today()
end

function M.pages_read_today()
    return reading_stats_pages_today.pages_read_today()
end

function M.seconds_per_weekday_since_monday()
    return reading_stats_week.seconds_per_weekday_since_monday()
end

function M.seconds_sum_by_local_date(start_unix, end_unix)
    return reading_stats_week.seconds_sum_by_local_date(start_unix, end_unix)
end

function M.pages_sum_by_local_date(start_unix, end_unix)
    return reading_stats_week.pages_sum_by_local_date(start_unix, end_unix)
end

return M

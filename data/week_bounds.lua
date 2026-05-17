local M = {}
function M.monday_midnight_unix_before_or_equal(ts)
    ts = assert(tonumber(ts), "unix ts required")
    local t = os.date("*t", ts)
    local w = tonumber(t.wday) or 1 -- Lua: 1=Sunday
    local days_since_monday = (w + 5) % 7

    -- Build local calendar time directly instead of subtracting 86400-chunks,
    -- so DST transitions do not skew midnight anchors.
    local anchor = {
        year = t.year,
        month = t.month,
        day = t.day - days_since_monday,
        hour = 0,
        min = 0,
        sec = 0,
        isdst = t.isdst,
    }
    return os.time(anchor)
end
return M

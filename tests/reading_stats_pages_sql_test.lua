-- Run from repo root: lua tests/reading_stats_pages_sql_test.lua
package.path = package.path .. ";./?.lua"

-- KOReader-less stock Lua cannot load libs/libkoreader-lfs; only _sql_fragment is exercised here.
if not package.loaded["logger"] then
    package.loaded["logger"] = { warn = function() end }
end
if not package.loaded["libs/libkoreader-lfs"] then
    package.loaded["libs/libkoreader-lfs"] = { attributes = function() return nil end }
end

local R = assert(require("data.reading_stats_pages_today"))
local s = R._sql_fragment_for_pages_since(1700000000)
assert(type(s) == "string")
assert(s:find("1700000000", 1, true))
assert(s:upper():find("PAGE_STAT"))
print("reading_stats_pages_sql_test: OK")

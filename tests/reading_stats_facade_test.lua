-- Smoke: syntax-only (full require needs KOReader libs at runtime).
package.path = package.path .. ";./?.lua"

local fh = assert(io.open("data/reading_stats.lua", "r"))
local src = fh:read("*a")
fh:close()
local chunk, err = load(src, "@data/reading_stats.lua")
assert(chunk, err)

print("reading_stats_facade_test: OK")

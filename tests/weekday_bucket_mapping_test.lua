-- Pure mapping parity: SQLite dow 0 Sun .. 6 Sat -> Mon=1 .. Sun=7
package.path = package.path .. ";./?.lua"

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

assert(sqlite_wday_to_bucket("0") == 7)
assert(sqlite_wday_to_bucket("1") == 1)
assert(sqlite_wday_to_bucket("2") == 2)
assert(sqlite_wday_to_bucket("6") == 6)
assert(sqlite_wday_to_bucket(nil) == nil)

print("weekday_bucket_mapping_test: OK")

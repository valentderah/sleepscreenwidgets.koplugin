--[[ LuaSettings `banner` table read/write helpers for appearance menu (spec §C.2). ]]
local Settings = require("settings")

local M = {}

function M.read_banner_table()
    return Settings:open():readSetting("banner") or {}
end

--- @param mutator function(banner_tbl) mutates in place
function M.with_banner(mutator)
    local lua = Settings:open()
    local banner = lua:readSetting("banner") or {}
    mutator(banner)
    lua:saveSetting("banner", banner)
    Settings:flush()
end

return M

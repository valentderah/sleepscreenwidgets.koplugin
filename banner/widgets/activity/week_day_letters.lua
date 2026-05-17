--[[ Lua wday: 1 = Sunday .. 7 = Saturday — одна латинская буква столбца (перевод через l10n при необходимости отдельно). ]]
local M = {}

local LETTERS = { "S", "M", "T", "W", "T", "F", "S" }

function M.letter_for_wday(wday)
    wday = math.floor(tonumber(wday) or 1)
    return LETTERS[wday] or "?"
end

return M

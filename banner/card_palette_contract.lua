--[[ Single source of truth for *names* of keys on ctx.card_palette / FrameStyle.card_colors_*.
    Values stay in banner/frame_style.lua. When adding a key:
    1) Add to both palette tables in frame_style.lua
    2) Append the same string to REQUIRED_KEYS below (keep grouped comments in sync).

    Semantic groups (documentation only):
    - Base: fill, border, text_primary, text_secondary
    - Progress: progress_track, progress_fill
    - Calendar chrome: calendar_dots, calendar_accent, calendar_muted, calendar_on_accent
    - Goal rings: ring_* (minutes/pages track + fill + fill_complete)
]]
local M = {}

M.REQUIRED_KEYS = {
    "fill",
    "border",
    "text_primary",
    "text_secondary",
    "progress_track",
    "progress_fill",
    "calendar_dots",
    "ring_minutes_track",
    "ring_minutes_fill",
    "ring_minutes_fill_complete",
    "ring_pages_track",
    "ring_pages_fill",
    "ring_pages_fill_complete",
    "calendar_accent",
    "calendar_muted",
    "calendar_on_accent",
}

--- @param palette table|nil
--- @return table array of missing key names (empty if complete)
function M.missing_keys(palette)
    local miss = {}
    if type(palette) ~= "table" then
        for _, k in ipairs(M.REQUIRED_KEYS) do
            miss[#miss + 1] = k
        end
        return miss
    end
    for _, k in ipairs(M.REQUIRED_KEYS) do
        if palette[k] == nil then
            miss[#miss + 1] = k
        end
    end
    return miss
end

return M

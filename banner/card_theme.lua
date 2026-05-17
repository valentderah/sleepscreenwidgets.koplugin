--[[ Palette for SleepWidgetCard from widget type + params.card_theme.
    grid_composer passes the result as ctx.card_palette. Special cases: calendar
    defaults to light; dark tile only when params.card_theme == "dark". Analog clock
    always uses dark tile.

    Returned table must include every key listed in banner/card_palette_contract.REQUIRED_KEYS. ]]
local FrameStyle = require("banner.frame_style")

local M = {}

local function palette_from_card_theme_param(ct)
    if ct == "dark" then
        return FrameStyle.card_colors_dark_tile()
    end
    if ct == "light" then
        return FrameStyle.card_colors_light()
    end
    return FrameStyle.card_colors_light()
end

local function clock_is_analog(params)
    local v = params.variant
    return type(v) == "string" and string.lower(v) == "analog"
end

--- @param widget_type string
--- @param params table|nil may contain card_theme, variant (clock)
--- @return table satisfies banner/card_palette_contract.REQUIRED_KEYS (same values as FrameStyle.card_colors_*)
function M.palette_for_placement(widget_type, params)
    if type(params) ~= "table" then
        params = {}
    end
    local ct = params.card_theme

    if widget_type == "calendar" then
        if ct == "dark" then
            return FrameStyle.card_colors_dark_tile()
        end
        return FrameStyle.card_colors_light()
    end

    if widget_type == "clock" and clock_is_analog(params) then
        return FrameStyle.card_colors_dark_tile()
    end

    -- Digital clock and other widget types: palette_from_card_theme_param(ct).

    return palette_from_card_theme_param(ct)
end

return M

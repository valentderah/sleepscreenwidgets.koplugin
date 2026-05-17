local Analog = require("banner.widgets.clock.analog")
local Font = require("ui/font")

local BannerText = require("banner.text")
local FrameStyle = require("banner.frame_style")
local WidgetSpan = require("banner.widget_span")

local M = {}

local function clock_variant_is_analog(params)
    if type(params) ~= "table" then
        return false
    end
    local v = params.variant
    if type(v) ~= "string" then
        return false
    end
    return string.lower(v) == "analog"
end

function M.build(params, ctx)
    params = params or {}
    if clock_variant_is_analog(params) then
        return Analog.build(params, ctx)
    end
    local B_SETT = ctx.B_SETT
    local HL_SETT = ctx.HL_SETT
    local fmt = (type(params.format) == "string" and params.format ~= "") and params.format or "%H:%M"
    local text = os.date(fmt)
    local sz = WidgetSpan.scaled_font_size(params.font_size or 22, ctx)
    local face = Font:getFace(params.font_face or "cfont", sz)
    local pal = ctx.card_palette or FrameStyle.card_colors_light()
    return BannerText.buildTextField(
        B_SETT,
        HL_SETT,
        text,
        face,
        ctx.cell_max_h,
        ctx.cell_max_w,
        true,
        false,
        pal.text_primary,
        pal.fill
    )
end

return M

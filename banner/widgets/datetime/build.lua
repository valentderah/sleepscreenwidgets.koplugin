local Device = require("device")
local Font = require("ui/font")
local Screen = Device.screen
local TextBoxWidget = require("ui/widget/textboxwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local FrameStyle = require("banner.frame_style")
local WidgetSpan = require("banner.widget_span")

local M = {}

--- Scale typography for merged cell span (1–3) plus a mild width-relative factor.
local function scaled_sizes(params, ctx, max_w_px)
    local span = WidgetSpan.col_span(ctx)
    local span_scale_lookup = {
        [1] = 0.74,
        [2] = 0.88,
        [3] = 1.0,
    }
    local span_scale = span_scale_lookup[span] or 0.74
    max_w_px = tonumber(max_w_px) or 100
    local w_ref = Screen:scaleBySize(420)
    local wr = 1
    if w_ref and w_ref > 0 then
        wr = math.sqrt(math.max(0.42, math.min(1.4, max_w_px / w_ref)))
    end
    local date_base = tonumber(params.date_size) or 15
    local time_base = tonumber(params.time_size) or 40
    local combined = span_scale * wr
    local date_px = math.max(11, math.floor(date_base * combined + 0.5))
    local time_px = math.max(18, math.floor(time_base * combined + 0.5))
    return date_px, time_px
end

function M.build(params, ctx)
    params = params or {}
    local max_w = ctx.cell_max_w or 100
    local pal = ctx.card_palette or FrameStyle.card_colors_light()
    local date_fmt = (type(params.date_format) == "string" and params.date_format ~= "")
        and params.date_format or "%A, %B %d"
    local time_fmt = (type(params.time_format) == "string" and params.time_format ~= "")
        and params.time_format or "%H:%M"
    local date_text = string.upper(os.date(date_fmt))
    local time_text = os.date(time_fmt)
    local date_size, time_size = scaled_sizes(params, ctx, max_w)

    local col = VerticalGroup:new{ align = "center" }
    table.insert(col, TextBoxWidget:new{
        text = date_text,
        face = Font:getFace("cfont", date_size),
        width = max_w,
        fgcolor = pal.text_secondary,
        alignment = "center",
        bold = false,
    })
    table.insert(col, VerticalSpan:new{ width = Screen:scaleBySize(4) })
    table.insert(col, TextBoxWidget:new{
        text = time_text,
        face = Font:getFace("cfont", time_size),
        width = max_w,
        fgcolor = pal.text_primary,
        alignment = "center",
        bold = true,
    })
    return col
end

return M

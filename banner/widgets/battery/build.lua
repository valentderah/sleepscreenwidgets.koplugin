local Device = require("device")
local Font = require("ui/font")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local Screen = Device.screen
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local BatteryGlyph = require("banner.widgets.battery.battery_glyph")
local BatteryRingLayout = require("banner.widgets.battery.battery_ring_layout")
local FrameStyle = require("banner.frame_style")
local WidgetSpan = require("banner.widget_span")

local M = {}

--- Same ring palette keys as `activity/day_build` so stamped dots match activity rings.
local function decorate_palette_goal_rings(pal)
    pal.ring_minutes_track = pal.ring_minutes_track or pal.progress_track
    pal.ring_minutes_fill = pal.ring_minutes_fill or pal.progress_fill
    pal.ring_minutes_fill_complete = pal.ring_minutes_fill_complete or pal.ring_minutes_fill
    pal.ring_pages_track = pal.ring_pages_track or pal.progress_track
    pal.ring_pages_fill = pal.ring_pages_fill or pal.progress_fill
    pal.ring_pages_fill_complete = pal.ring_pages_fill_complete or pal.ring_pages_fill
end

local function battery_arc_fill(pal, frac)
    frac = math.max(0, math.min(1, tonumber(frac) or 0))
    if frac >= 1 then
        return pal.ring_pages_fill_complete or pal.ring_pages_fill
    end
    return pal.ring_pages_fill
end

function M.build(_params, ctx)
    if not Device:hasBattery() then
        return nil
    end
    local power = Device:getPowerDevice()
    if not power then
        return nil
    end
    local lvl = power:getCapacity() or 0
    local cap = math.max(0, math.min(100, math.floor(tonumber(lvl) or 0)))
    local label = string.format("%d%%", cap)

    local pal = ctx.card_palette or FrameStyle.card_colors_light()
    decorate_palette_goal_rings(pal)
    local max_w = tonumber(ctx.cell_max_w) or 160
    local max_h = tonumber(ctx.cell_max_h) or 120

    local gap_px = Screen:scaleBySize(4)
    --- Keeps descenders of bold percent inside padded slot (SlotFillHolder clips hard edges).
    local bottom_pad = Screen:scaleBySize(4)

    local pct_fs = WidgetSpan.scaled_font_size(24, ctx)
    local pct
    local S
    while pct_fs >= 11 do
        pct = TextWidget:new{
            text = label,
            face = Font:getFace("cfont", pct_fs),
            fgcolor = pal.text_primary,
            bold = true,
            padding = 0,
        }
        local pct_h = pct:getSize().h
        S = BatteryRingLayout.ring_side_vertical_fill(max_w, max_h, gap_px, pct_h, bottom_pad)
        local need_h = S + gap_px + pct_h + bottom_pad
        if need_h <= max_h then
            break
        end
        pct_fs = pct_fs - 2
    end

    if pct_fs < 11 then
        pct_fs = 11
        pct = TextWidget:new{
            text = label,
            face = Font:getFace("cfont", pct_fs),
            fgcolor = pal.text_primary,
            bold = true,
            padding = 0,
        }
        local pct_h = pct:getSize().h
        S = BatteryRingLayout.ring_side_vertical_fill(max_w, max_h, gap_px, pct_h, bottom_pad)
    end

    local pct_h = pct:getSize().h
    S = BatteryRingLayout.ring_side_vertical_fill(max_w, max_h, gap_px, pct_h, bottom_pad)

    --- When S hits max_w, column is shorter than max_h — extend height so SlotFillHolder does not vertically center.
    local content_h = S + gap_px + pct_h + bottom_pad
    local bottom_slack = math.max(0, math.floor(max_h - content_h))

    local glyph = BatteryGlyph:new{
        size = S,
        capacity = cap,
        bg_color = pal.fill,
        c_track = pal.ring_pages_track,
        c_fill = battery_arc_fill(pal, cap / 100),
        icon_color = pal.text_primary,
    }

    --- SlotFillHolder centers children; span full cell_max_w so content stays left-aligned.
    local inner_w = math.max(S, pct:getSize().w)
    local tail_w = math.max(0, math.floor(max_w - inner_w))

    local col = VerticalGroup:new{ align = "left" }
    table.insert(col, HorizontalGroup:new{
        align = "bottom",
        glyph,
    })
    table.insert(col, VerticalSpan:new{ width = gap_px })
    table.insert(col, HorizontalGroup:new{
        align = "bottom",
        pct,
    })
    if bottom_pad > 0 then
        table.insert(col, VerticalSpan:new{ width = bottom_pad })
    end
    if bottom_slack > 0 then
        table.insert(col, VerticalSpan:new{ width = bottom_slack })
    end

    return HorizontalGroup:new{
        align = "bottom",
        col,
        HorizontalSpan:new{ width = tail_w },
    }
end

return M

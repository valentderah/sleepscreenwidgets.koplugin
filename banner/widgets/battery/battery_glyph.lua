--[[ Ring progress + battery outline inside hole (palette-driven colors). ]]
local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Geom = require("ui/geometry")
local Widget = require("ui/widget/widget")

local RL = require("banner.widgets.activity.rings_layout")
local Screen = Device.screen

local TWO_PI = 2 * math.pi

local function bb_type_from(bb)
    if bb and bb.getType then
        local ty = bb:getType()
        if ty then
            return ty
        end
    end
    return Screen.bb and Screen.bb:getType() or Blitbuffer.TYPE_BBRGB32
end

local function stamp_full_ring(bb_, cx, cy, r, stroke_w, color)
    local rh = math.max(1, math.floor(stroke_w / 2 + 1e-6))
    local n = math.max(64, math.floor(TWO_PI * r / (stroke_w * 0.42 + 0.01)))
    for i = 0, n - 1 do
        local th = i / n * TWO_PI
        local px = cx + math.cos(th) * r
        local py = cy + math.sin(th) * r
        bb_:paintCircle(math.floor(px + 0.5), math.floor(py + 0.5), rh, color)
    end
end

local function stamp_arc_cw(bb_, cx, cy, r, stroke_w, frac, color)
    frac = math.max(0, math.min(1, tonumber(frac) or 0))
    if frac <= 0 then
        return
    end
    local rh = math.max(1, math.floor(stroke_w / 2 + 1e-6))
    local a0 = -math.pi / 2
    local span = frac * TWO_PI
    local n = math.max(24, math.floor(r * math.abs(span) / (stroke_w * 0.34 + 0.01)))
    for i = 0, n do
        local t = i / n
        local th = a0 + t * span
        local px = cx + math.cos(th) * r
        local py = cy + math.sin(th) * r
        bb_:paintCircle(math.floor(px + 0.5), math.floor(py + 0.5), rh, color)
    end
    local th_end = a0 + span
    local ex = cx + math.cos(th_end) * r
    local ey = cy + math.sin(th_end) * r
    bb_:paintCircle(math.floor(ex + 0.5), math.floor(ey + 0.5), rh, color)
end

local function stamp_segment(bb, x0, y0, x1, y1, rw, color)
    local dx = x1 - x0
    local dy = y1 - y0
    local len = math.max(1, math.floor(math.sqrt(dx * dx + dy * dy) + 0.5))
    for i = 0, len do
        local t = i / len
        bb:paintCircle(math.floor(x0 + dx * t + 0.5), math.floor(y0 + dy * t + 0.5), rw, color)
    end
end

--- Portrait battery: thin terminal band on top, body below (cf. iOS / 90° from sideways glyph).
local function paint_battery_outline(bb, cx, cy, hole_r, color)
    hole_r = tonumber(hole_r) or 10
    local rw = math.max(1, math.floor(hole_r * 0.075 + 0.5))
    --- Narrow body + terminal (was ~1.05×hole_r — read as overly wide in the ring hole).
    local bw = math.floor(hole_r * 0.72 + 0.5)
    local bh = math.floor(hole_r * 0.92 + 0.5)
    local tip_h = math.max(rw * 2, math.floor(hole_r * 0.14 + 0.5))
    local tip_w = math.floor(bw * 0.36 + 0.5)
    local gap = math.max(1, math.floor(hole_r * 0.06 + 0.5))

    local total_h = tip_h + gap + bh
    local top = cy - total_h / 2

    local tip_left = cx - tip_w / 2
    local tip_right = cx + tip_w / 2
    local tip_top = top
    local tip_bottom = top + tip_h
    stamp_segment(bb, tip_left, tip_top, tip_right, tip_top, rw, color)
    stamp_segment(bb, tip_left, tip_bottom, tip_right, tip_bottom, rw, color)
    stamp_segment(bb, tip_left, tip_top, tip_left, tip_bottom, rw, color)
    stamp_segment(bb, tip_right, tip_top, tip_right, tip_bottom, rw, color)

    local body_top = tip_bottom + gap
    local body_bottom = body_top + bh
    local body_left = cx - bw / 2
    local body_right = cx + bw / 2
    stamp_segment(bb, body_left, body_top, body_right, body_top, rw, color)
    stamp_segment(bb, body_left, body_bottom, body_right, body_bottom, rw, color)
    stamp_segment(bb, body_left, body_top, body_left, body_bottom, rw, color)
    stamp_segment(bb, body_right, body_top, body_right, body_bottom, rw, color)
end

local BatteryGlyph = Widget:extend{
    size = 96,
    capacity = 100,
    bg_color = Blitbuffer.COLOR_WHITE,
    c_track = Blitbuffer.COLOR_GRAY_9,
    c_fill = Blitbuffer.COLOR_BLACK,
    icon_color = Blitbuffer.COLOR_BLACK,
}

function BatteryGlyph:init()
    local S = math.max(24, math.floor(tonumber(self.size) or 96))
    self.size = S
    self.dimen = Geom:new{ w = S, h = S }
    self.capacity = math.max(0, math.min(100, math.floor(tonumber(self.capacity) or 0)))
end

function BatteryGlyph:getSize()
    local S = self.size
    return Geom:new{ x = 0, y = 0, w = S, h = S }
end

function BatteryGlyph:paintTo(bb, ox, oy)
    local S = self.size
    local tmp = Blitbuffer.new(S, S, bb_type_from(bb))
    tmp:paintRect(0, 0, S, S, self.bg_color)

    local stroke, _gap, r_out, _, _cx0, cy = RL.ring_geometry(S, false)
    --- Flush ring to x=0 so slot + SlotFillHolder left-align match activity-style titles.
    local cx = r_out + stroke / 2
    stamp_full_ring(tmp, cx, cy, r_out, stroke, self.c_track)
    stamp_arc_cw(tmp, cx, cy, r_out, stroke, self.capacity / 100, self.c_fill)

    local hole_r = math.max(4, r_out - stroke)
    paint_battery_outline(tmp, cx, cy, hole_r, self.icon_color)

    bb:blitFrom(tmp, ox, oy, 0, 0, S, S)
    tmp:free()
end

return BatteryGlyph

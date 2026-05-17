--[[ Concentric activity rings painted to BB (Apple-style capped arcs).
    Geometry from `banner.widgets.activity.rings_layout`. ]]
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

local ActivityRings = Widget:extend{
    size = 96,
    bg_color = Blitbuffer.COLOR_WHITE,
    two_rings = false,
    --- When true, outer ring’s left stroke aligns to x=0 (day card matches battery glyph).
    flush_ring_left = false,
    pct_outer = 0,
    pct_inner = 0,
    c_track_outer = Blitbuffer.COLOR_GRAY_9,
    c_fill_outer = Blitbuffer.COLOR_BLACK,
    c_track_inner = Blitbuffer.COLOR_GRAY_9,
    c_fill_inner = Blitbuffer.COLOR_BLACK,
}

function ActivityRings:init()
    local S = math.max(8, math.floor(tonumber(self.size) or 96))
    self.size = S
    self.dimen = Geom:new{ w = S, h = S }
end

function ActivityRings:getSize()
    local S = self.size
    return Geom:new{ x = 0, y = 0, w = S, h = S }
end

function ActivityRings:paintTo(bb, ox, oy)
    local S = self.size
    local tmp = Blitbuffer.new(S, S, bb_type_from(bb))
    tmp:paintRect(0, 0, S, S, self.bg_color)

    local stroke, _, r_out, r_in, cx0, cy = RL.ring_geometry(S, self.two_rings)
    local cx = cx0
    if self.flush_ring_left then
        cx = r_out + stroke / 2
    end

    stamp_full_ring(tmp, cx, cy, r_out, stroke, self.c_track_outer)
    stamp_arc_cw(tmp, cx, cy, r_out, stroke, self.pct_outer, self.c_fill_outer)

    if self.two_rings and r_in and r_in > 0 then
        stamp_full_ring(tmp, cx, cy, r_in, stroke, self.c_track_inner)
        stamp_arc_cw(tmp, cx, cy, r_in, stroke, self.pct_inner, self.c_fill_inner)
    end

    bb:blitFrom(tmp, ox, oy, 0, 0, S, S)
    tmp:free()
end

return ActivityRings

--[[
    Horizontal progress bar with rounded track and rounded fill.

    KOReader's stock ProgressWidget paints the percentage fill with plain paintRect,
    so only the trough looks rounded; this widget paints both layers with rounded rects.
]]
local Blitbuffer = require("ffi/blitbuffer")
local Geom = require("ui/geometry")
local Widget = require("ui/widget/widget")

local RoundedProgressBar = Widget:extend{
    width = nil,
    height = nil,
    percentage = 0,
    bgcolor = Blitbuffer.COLOR_WHITE,
    fillcolor = Blitbuffer.COLOR_BLACK,
    radius = 0,
    margin_h = 0,
    margin_v = 0,
}

function RoundedProgressBar:init()
    local w = math.floor(tonumber(self.width) or 0)
    local he = math.floor(tonumber(self.height) or 0)
    self.dimen = Geom:new{ w = w, h = he }
end

function RoundedProgressBar:getSize()
    return Geom:new{
        x = 0,
        y = 0,
        w = self.dimen.w,
        h = self.dimen.h,
    }
end

function RoundedProgressBar:paintTo(bb, x, y)
    local my = self:getSize()
    if not self.dimen then
        self.dimen = Geom:new{ w = my.w, h = my.h }
    else
        self.dimen.x = x
        self.dimen.y = y
        self.dimen.w = my.w
        self.dimen.h = my.h
    end
    local w = my.w
    local h = my.h
    if w <= 0 or h <= 0 then
        return
    end

    local mh = math.floor(tonumber(self.margin_h) or 0)
    local mv = math.floor(tonumber(self.margin_v) or 0)
    local ix = math.floor(x + mh)
    local iy = math.floor(y + mv)
    local iw = w - 2 * mh
    local ih = h - 2 * mv
    if iw <= 0 or ih <= 0 then
        return
    end

    local pct = tonumber(self.percentage) or 0
    pct = math.max(0, math.min(1, pct))

    local req_r = tonumber(self.radius) or 0
    local r_track = math.max(0, math.min(req_r, math.floor(ih / 2), math.floor(iw / 2)))

    if r_track == 0 then
        bb:paintRect(ix, iy, iw, ih, self.bgcolor)
        if pct > 0 then
            local fw = math.max(1, math.min(iw, math.ceil(iw * pct)))
            bb:paintRect(ix, iy, fw, ih, self.fillcolor)
        end
        return
    end

    bb:paintRoundedRect(ix, iy, iw, ih, self.bgcolor, r_track)

    if pct <= 0 then
        return
    end

    local fw = math.max(1, math.ceil(iw * pct))
    fw = math.min(iw, fw)
    local r_fill = math.min(r_track, math.floor(ih / 2), math.floor(fw / 2))
    bb:paintRoundedRect(ix, iy, fw, ih, self.fillcolor, r_fill)
end

return RoundedProgressBar

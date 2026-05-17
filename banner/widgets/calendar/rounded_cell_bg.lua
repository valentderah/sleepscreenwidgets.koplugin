local Blitbuffer = require("ffi/blitbuffer")
local Geom = require("ui/geometry")
local Widget = require("ui/widget/widget")

local RoundedCellBg = Widget:extend{
    width = nil,
    height = nil,
    radius = nil,
    bgcolor = Blitbuffer.COLOR_BLACK,
}

function RoundedCellBg:init()
    local w = math.floor(tonumber(self.width) or 0)
    local h = math.floor(tonumber(self.height) or 0)
    self.dimen = Geom:new{ x = 0, y = 0, w = w, h = h }
end

function RoundedCellBg:getSize()
    return Geom:new{ x = 0, y = 0, w = self.dimen.w, h = self.dimen.h }
end

function RoundedCellBg:paintTo(bb, x, y)
    local my = self:getSize()
    self.dimen.x = x
    self.dimen.y = y
    self.dimen.w = my.w
    self.dimen.h = my.h
    local w = my.w
    local h = my.h
    if w <= 0 or h <= 0 then
        return
    end
    local req_r = tonumber(self.radius)
    if req_r == nil then
        req_r = math.min(math.floor(w / 2), math.floor(h / 2))
    end
    local r = math.max(0, math.min(req_r, math.floor(h / 2), math.floor(w / 2)))
    bb:paintRoundedRect(x, y, w, h, self.bgcolor, r)
end

return RoundedCellBg

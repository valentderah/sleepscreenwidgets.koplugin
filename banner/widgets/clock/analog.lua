--[[ Analog clock face for unified `clock` widget when params.variant == "analog`.
    Cells filled with shell color (OUTER or card fill on dark tiles), square dial, hands/hub.
]]
local Blitbuffer = require("ffi/blitbuffer")
local FrameStyle = require("banner.frame_style")
local Geom = require("ui/geometry")
local Screen = require("device").screen
local Widget = require("ui/widget/widget")

local M = {}

local OUTER = Blitbuffer.ColorRGB32(0x1C, 0x1C, 0x1D, 0xFF)
local FACE = Blitbuffer.COLOR_WHITE
local TICK_C = Blitbuffer.ColorRGB32(0x8C, 0x8C, 0x8C, 0xFF)
local HAND = Blitbuffer.COLOR_BLACK

local function shell_color_for_ctx(ctx)
    local pal = (ctx and ctx.card_palette) or FrameStyle.card_colors_light()
    if pal.fill == Blitbuffer.COLOR_BLACK then
        return Blitbuffer.COLOR_BLACK
    end
    return OUTER
end

local function rotate_bb(source, dest, center_x, center_y, angle_rad, only_color)
    local mw, mh = source:getWidth() - 1, source:getHeight() - 1
    local s, c = math.sin(angle_rad), math.cos(angle_rad)
    for x = 0, mw do
        for y = 0, mh do
            local rel_x = x - center_x
            local rel_y = y - center_y
            local old_x = math.floor(center_x + (rel_x * c - rel_y * s) + 0.5)
            local old_y = math.floor(center_y + (rel_x * s + rel_y * c) + 0.5)
            if old_x >= 0 and old_x <= mw and old_y >= 0 and old_y <= mh then
                local pixel = source:getPixel(old_x, old_y)
                if (not only_color) or pixel == only_color then
                    dest:setPixel(x, y, pixel)
                end
            end
        end
    end
end

local function draw_static_dial(size, bb_type_, shell_outer)
    shell_outer = shell_outer or OUTER
    local bb_type = bb_type_
    if not bb_type then
        bb_type = Screen.bb and Screen.bb:getType() or Blitbuffer.TYPE_BBRGB32
    end
    local bb = Blitbuffer.new(size, size, bb_type)
    local cx = size / 2
    local cy = size / 2
    bb:paintRect(0, 0, size, size, shell_outer)
    local Ri = math.floor(71 / 158 * size + 0.5)
    Ri = math.max(4, math.min(Ri, math.floor(size / 2) - 1))
    bb:paintCircle(math.floor(cx), math.floor(cy), Ri, FACE)
    local r_inner = Ri * 0.69
    local r_outer = Ri * 0.93
    local thick = math.max(2, math.floor(size / 28))
    local span = math.max(r_outer - r_inner, 1)
    local steps_r = math.max(5, math.floor(span))
    for h = 0, 11 do
        local a = -math.pi / 2 + h * (math.pi / 6)
        for st = 0, steps_r do
            local t = st / steps_r
            local r = r_inner + t * (r_outer - r_inner)
            local px = math.floor(cx + math.cos(a) * r + 0.5)
            local py = math.floor(cy + math.sin(a) * r + 0.5)
            bb:paintRect(
                px - math.floor(thick / 2),
                py - math.floor(thick / 2),
                thick,
                thick,
                TICK_C
            )
        end
    end
    return bb
end

local function draw_hand(size, length_ratio, base_width_ratio, tip_width_ratio, bb_type, face_fill, stroke)
    local bb = Blitbuffer.new(size, size, bb_type)
    bb:fill(face_fill)
    local center = size / 2
    local hand_length = size * length_ratio
    local base_w = size * base_width_ratio
    local tip_w = size * tip_width_ratio
    local y_tip = center - hand_length
    local y_base = center
    for y = math.floor(y_tip), math.floor(y_base) do
        local denom = y_base - y_tip
        local progress = denom ~= 0 and (y - y_tip) / denom or 0
        local width = tip_w + (base_w - tip_w) * progress
        local left = center - width / 2
        bb:paintRect(math.floor(left), y, math.floor(width), 1, stroke)
    end
    local tip_r = math.floor(tip_w / 2)
    bb:paintCircle(math.floor(center), math.floor(y_tip), tip_r, stroke)
    return bb
end

local function bb_type_best()
    local sc = Screen.bb
    if sc ~= nil and type(sc.getType) == "function" then
        return sc:getType()
    end
    return Blitbuffer.TYPE_BBRGB32
end

local dial_cache = {}
local hour_tpl_cache = {}
local min_tpl_cache = {}

local DIAL_CACHE_VER = 3

local function dial_shell_cache_suffix(shell_outer)
    return shell_outer == Blitbuffer.COLOR_BLACK and ":blk" or ":ios"
end

local function get_static_dial(size, shell_outer)
    shell_outer = shell_outer or OUTER
    local key = DIAL_CACHE_VER .. ":" .. tostring(size) .. dial_shell_cache_suffix(shell_outer)
    local fb = dial_cache[key]
    if not fb then
        fb = draw_static_dial(size, bb_type_best(), shell_outer)
        dial_cache[key] = fb
    end
    return fb
end

local function get_hour_template(size)
    local key = tostring(size)
    local hh = hour_tpl_cache[key]
    if not hh then
        hh = draw_hand(size, 0.26, 1 / 11, 1 / 28, bb_type_best(), FACE, HAND)
        hour_tpl_cache[key] = hh
    end
    return hh
end

local function get_minute_template(size)
    local key = tostring(size)
    local mm = min_tpl_cache[key]
    if not mm then
        mm = draw_hand(size, 0.38, 1 / 13, 1 / 30, bb_type_best(), FACE, HAND)
        min_tpl_cache[key] = mm
    end
    return mm
end

local function compose_square_face(S, hours, minutes, shell_outer)
    local compose = Blitbuffer.new(S, S, bb_type_best())
    local dial = get_static_dial(S, shell_outer)
    compose:blitFrom(dial, 0, 0, 0, 0, S, S)
    local center = S / 2
    local hour_rad = -math.pi / 6
    local minute_rad = -math.pi / 30
    local hh = get_hour_template(S)
    local mh = get_minute_template(S)
    rotate_bb(hh, compose, center, center, (hours + minutes / 60) * hour_rad, HAND)
    rotate_bb(mh, compose, center, center, minutes * minute_rad, HAND)
    return compose
end

local function compose_full_cell(w, h, face_pct, hours, minutes, shell_outer)
    shell_outer = shell_outer or OUTER
    local bb_type = bb_type_best()
    local bg = Blitbuffer.new(w, h, bb_type)
    local m = math.min(w, h)
    bg:paintRect(0, 0, w, h, shell_outer)
    face_pct = math.max(50, math.min(100, math.floor(tonumber(face_pct) or 100)))
    local S = math.floor(m * face_pct / 100)
    S = math.max(24, math.min(m, S))
    if S % 2 == 1 then
        S = S - 1
    end
    local sq = compose_square_face(S, hours, minutes, shell_outer)
    local ox = math.floor((w - S) / 2)
    local oy = math.floor((h - S) / 2)
    bg:blitFrom(sq, ox, oy, 0, 0, S, S)
    sq:free()
    local cx = math.floor(w / 2)
    local cy = math.floor(h / 2)
    local hub_r = math.max(2, math.floor(S / 28))
    bg:paintCircle(cx, cy, hub_r, HAND)
    return bg
end

local AnalogClock = Widget:extend{
    cell_w = 96,
    cell_h = 96,
    face_pct = 100,
    outer_shell = OUTER,
}

function AnalogClock:init()
    self.dimen = Geom:new{
        w = self.cell_w,
        h = self.cell_h,
    }
end

function AnalogClock:paintTo(bb, px, py)
    local h = tonumber(os.date("%H"))
    local mi = tonumber(os.date("%M"))
    local composed = compose_full_cell(self.cell_w, self.cell_h, self.face_pct, h, mi, self.outer_shell)
    bb:blitFrom(composed, px, py, 0, 0, self.cell_w, self.cell_h)
    composed:free()
end

function M.build(params, ctx)
    params = params or {}
    local w = math.max(2, math.floor(tonumber(ctx.cell_max_w) or 80))
    local h = math.max(2, math.floor(tonumber(ctx.cell_max_h) or 80))
    local pct = tonumber(params.diameter_pct) or 100
    return AnalogClock:new{
        cell_w = w,
        cell_h = h,
        face_pct = pct,
        outer_shell = shell_color_for_ctx(ctx),
    }
end

return M

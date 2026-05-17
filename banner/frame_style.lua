local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Screen = Device.screen

local M = {}

function M.scale(n)
    return Screen:scaleBySize(n)
end

function M.card_border_width(_B_SETT)
    return M.scale(4)
end

-- Palette key names: keep in sync with banner/card_palette_contract.lua REQUIRED_KEYS.

function M.card_colors_light()
    return {
        fill = Blitbuffer.COLOR_WHITE,
        border = Blitbuffer.COLOR_BLACK,
        text_primary = Blitbuffer.COLOR_BLACK,
        text_secondary = Blitbuffer.COLOR_GRAY_3, -- tune on e-ink toward #666
        progress_track = Blitbuffer.COLOR_GRAY_9, -- tune toward #E0E0E0
        progress_fill = Blitbuffer.COLOR_BLACK,
        calendar_dots = Blitbuffer.COLOR_BLACK,
        -- Darker tracks/fills so stamped ring arcs read clearly on white card (e-ink).
        ring_minutes_track = Blitbuffer.ColorRGB32(0xAC, 0xAC, 0xAC, 0xFF),
        ring_minutes_fill = Blitbuffer.ColorRGB32(0x8E, 0x16, 0x2C, 0xFF),
        ring_minutes_fill_complete = Blitbuffer.ColorRGB32(0x6B, 0x10, 0x1F, 0xFF),
        ring_pages_track = Blitbuffer.ColorRGB32(0xAC, 0xAC, 0xAC, 0xFF),
        ring_pages_fill = Blitbuffer.ColorRGB32(0x1C, 0x64, 0x34, 0xFF),
        ring_pages_fill_complete = Blitbuffer.ColorRGB32(0x14, 0x4A, 0x26, 0xFF),
        calendar_accent = Blitbuffer.ColorRGB32(0xFF, 0x3B, 0x30, 0xFF),
        calendar_muted = Blitbuffer.ColorRGB32(0x8E, 0x8E, 0x93, 0xFF),
        calendar_on_accent = Blitbuffer.ColorRGB32(0xFF, 0xFF, 0xFF, 0xFF),
    }
end

function M.card_colors_dark_tile()
    local light = M.card_colors_light()
    return {
        fill = Blitbuffer.COLOR_BLACK,
        border = light.border,
        text_primary = Blitbuffer.COLOR_WHITE,
        text_secondary = Blitbuffer.COLOR_GRAY_9,
        progress_track = light.progress_track,
        progress_fill = light.progress_fill,
        calendar_dots = Blitbuffer.COLOR_WHITE,
        -- Slightly deeper accent + muted tracks on black tile (less “neon” on e-ink).
        ring_minutes_track = Blitbuffer.ColorRGB32(0x36, 0x1C, 0x22, 0xFF),
        ring_minutes_fill = Blitbuffer.ColorRGB32(0xE8, 0x3A, 0x52, 0xFF),
        ring_minutes_fill_complete = Blitbuffer.ColorRGB32(0xC2, 0x2E, 0x44, 0xFF),
        ring_pages_track = Blitbuffer.ColorRGB32(0x1A, 0x32, 0x22, 0xFF),
        ring_pages_fill = Blitbuffer.ColorRGB32(0x4E, 0xC2, 0x64, 0xFF),
        ring_pages_fill_complete = Blitbuffer.ColorRGB32(0x3A, 0xAA, 0x58, 0xFF),
        calendar_accent = Blitbuffer.ColorRGB32(0xFF, 0x3B, 0x30, 0xFF),
        calendar_muted = Blitbuffer.ColorRGB32(0xAE, 0xAE, 0xB2, 0xFF),
        calendar_on_accent = Blitbuffer.ColorRGB32(0xFF, 0xFF, 0xFF, 0xFF),
    }
end

return M

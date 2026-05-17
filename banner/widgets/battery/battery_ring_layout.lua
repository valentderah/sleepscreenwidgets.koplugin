--[[ Pure layout for battery ring size + left inset (host-testable, no FFI). ]]

local RL = require("banner.widgets.activity.rings_layout")

local M = {}

--- Left distance from widget x=0 to leftmost stroke of the ring (single ring).
function M.ring_left_inset(S)
    S = math.max(24, math.floor(tonumber(S) or 24))
    local stroke, _gap, r_out = RL.ring_geometry(S, false)
    local cx = S / 2
    return math.max(0, math.floor(cx - r_out - stroke / 2 + 0.5))
end

--- Square side S: fits under (max_w, max_h) reserving vertical space for percent + gap.
function M.battery_ring_square_side(max_w, max_h, gap_px, pct_line_px)
    max_w = math.max(24, tonumber(max_w) or 24)
    max_h = math.max(24, tonumber(max_h) or 24)
    gap_px = math.max(0, tonumber(gap_px) or 0)
    pct_line_px = math.max(18, tonumber(pct_line_px) or 24)
    local avail_h = max_h - gap_px - pct_line_px
    avail_h = math.max(24, math.floor(avail_h))
    local cap_w = math.floor(max_w * 0.95 + 0.5)
    return math.max(24, math.min(avail_h, cap_w, max_w))
end

--- Same as sizing ring when caller knows measured percent row height + bottom safe inset.
function M.ring_square_side_fit(max_w, max_h, gap_px, pct_h, bottom_pad)
    max_w = math.max(24, tonumber(max_w) or 24)
    max_h = math.max(24, tonumber(max_h) or 24)
    gap_px = math.max(0, tonumber(gap_px) or 0)
    pct_h = math.max(10, tonumber(pct_h) or 22)
    bottom_pad = math.max(0, tonumber(bottom_pad) or 0)
    local avail_h = max_h - gap_px - pct_h - bottom_pad
    avail_h = math.floor(avail_h)
    local cap_w = math.floor(max_w * 0.95 + 0.5)
    local side = math.min(cap_w, max_w, avail_h)
    return math.max(20, side)
end

--- Square side: remaining height under gap/pct/bottom and full slot width (no 0.95 shrink).
function M.ring_side_vertical_fill(max_w, max_h, gap_px, pct_h, bottom_pad)
    max_w = math.max(24, tonumber(max_w) or 24)
    max_h = math.max(24, tonumber(max_h) or 24)
    gap_px = math.max(0, tonumber(gap_px) or 0)
    pct_h = math.max(10, tonumber(pct_h) or 22)
    bottom_pad = math.max(0, tonumber(bottom_pad) or 0)
    local avail_h = max_h - gap_px - pct_h - bottom_pad
    avail_h = math.floor(avail_h)
    local side = math.min(max_w, avail_h)
    return math.max(20, side)
end

return M

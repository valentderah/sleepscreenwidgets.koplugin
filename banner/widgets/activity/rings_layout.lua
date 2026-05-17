--[[ Pure layout for activity rings + label helpers (no FFI). ]]

local M = {}

function M.rings_square_side(max_w, max_h, text_reserve)
    max_w = math.max(24, tonumber(max_w) or 24)
    max_h = math.max(24, tonumber(max_h) or 24)
    text_reserve = math.max(0, tonumber(text_reserve) or 0)
    local reserve_cap = math.floor(max_h * 0.38)
    if reserve_cap > 0 then
        text_reserve = math.min(text_reserve, reserve_cap)
    end
    local avail_h = math.max(24, max_h - text_reserve)
    local min_side = math.min(max_w, max_h)
    local generous = math.floor(min_side * 0.90 + 0.5)
    return math.max(24, math.min(max_w, avail_h, generous))
end

function M.ring_geometry(S, two_rings)
    S = math.max(24, tonumber(S) or 24)
    local stroke = math.max(5, math.min(18, math.floor(S / 9 + 0.5)))
    local gap = math.max(2, math.floor(stroke * 0.48 + 0.5))
    local cx = S / 2
    local cy = S / 2
    if two_rings then
        local r_outer = cx - stroke - 1
        local r_inner = r_outer - gap - stroke * 2
        r_inner = math.max(math.floor(stroke * 2.5), r_inner)
        return stroke, gap, r_outer, r_inner, cx, cy
    end
    local r = cx - stroke - 1
    r = math.max(math.floor(stroke * 3), r)
    return stroke, gap, r, nil, cx, cy
end

function M.progress_draw_frac(current, goal)
    local den = tonumber(goal) or 0
    if den <= 0 then
        return 0
    end
    local c = math.max(0, tonumber(current) or 0)
    return math.max(0, math.min(1, c / den))
end

function M.xy_line(current, goal, suffix_literal)
    local cur = tostring(math.floor(tonumber(current) or 0))
    local gv = tostring(math.floor(tonumber(goal) or 0))
    local suf = suffix_literal
    suf = (type(suf) == "string" and suf ~= "") and (" " .. suf) or ""
    return cur .. " / " .. gv .. suf
end

return M

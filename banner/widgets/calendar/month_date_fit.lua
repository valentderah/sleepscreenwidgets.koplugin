--[[ Pure helpers: pick date-cell font size so "31" fits narrow columns after card padding. ]]

local WidgetSpan = require("banner.widget_span")

local M = {}

M.DEFAULT_START_CELL_SZ = 12
M.MIN_CELL_SZ = 9

--- Estimated pixel width for two bold digit glyphs (widest common day label).
function M.estimated_day_pair_width_px(cell_sz, ctx)
    local fs = WidgetSpan.scaled_font_size(cell_sz, ctx)
    return math.ceil(fs * 2.45)
end

--- Returns cell_sz, pad_px (caller passes scaled pad via scale_fn).
function M.pick_date_cell_sz_and_pad(cell_w, ctx, scale_fn)
    scale_fn = scale_fn or function(n)
        return n
    end
    local pad_lo = scale_fn(2)
    local pad_hi = scale_fn(3)
    local sz = M.DEFAULT_START_CELL_SZ
    while sz >= M.MIN_CELL_SZ do
        for _, pad in ipairs({ pad_hi, pad_lo }) do
            local inner = cell_w - 2 * pad
            local margin = scale_fn(2)
            if inner > margin and M.estimated_day_pair_width_px(sz, ctx) <= inner - margin then
                return sz, pad
            end
        end
        sz = sz - 1
    end
    return M.MIN_CELL_SZ, pad_lo
end

return M

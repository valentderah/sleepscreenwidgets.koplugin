local Device = require("device")
local FrameContainer = require("ui/widget/container/framecontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local Screen = Device.screen
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local util = require("util")

local BannerDp = require("grid.banner_dp")
local Config = require("config")
local CardTheme = require("banner.card_theme")
local CellSlot = require("grid.cell_slot")
local GridModel = require("grid.grid_model")
local LayoutSpec = require("grid.layout_spec")
local Registry = require("banner.widgets.registry")
local SleepWidgetCard = require("grid.sleep_widget_card")
local SlotFillHolder = require("grid.slot_fill_holder")

local GridComposer = {}

local function default_span(type_id)
    Registry.ensure_registered()
    return Registry.default_col_span(type_id)
end

local LAYOUT = Config.GRID_LAYOUT

function GridComposer.compose(placements, ctx)
    Registry.ensure_registered()

    local B_SETT = ctx.B_SETT
    local merged_banner = {}
    util.tableMerge(merged_banner, Config.DEFAULT_BANNER)
    util.tableMerge(merged_banner, B_SETT or {})

    local banner_dp = BannerDp.effective_dp(merged_banner)
    local spec = LayoutSpec.compute({
        screen_w = ctx.screen_w,
        screen_h = ctx.screen_h,
        grid_inner_h = ctx.grid_inner_h or ctx.screen_h,
        scale_by_size = function(n)
            return Screen:scaleBySize(n)
        end,
        banner_dp = banner_dp,
    })

    local edge_ml = spec.edge_ml_px
    local edge_mr = spec.edge_mr_px
    local edge_mt = spec.edge_mt_px
    local edge_mb = spec.edge_mb_px
    local slot_w = spec.slot_w_px
    local row_h = spec.row_h_px
    local gutter_x = spec.gutter_x_px
    local gutter_y = spec.gutter_y_px

    local card_pad = Screen:scaleBySize(banner_dp.widget_padding_dp)
    local card_r = Screen:scaleBySize(banner_dp.widget_radius_dp)

    local grid_cols = GridModel.GRID_COLS
    local grid_rows = GridModel.GRID_ROWS

    local resolved = GridModel.placementsWithSpan(placements or {}, default_span)
    local by_row = {}
    for r = 1, grid_rows do
        by_row[r] = {}
    end
    for _, p in ipairs(resolved) do
        if p.row >= 1 and p.row <= grid_rows then
            table.insert(by_row[p.row], p)
        end
    end
    for r = 1, grid_rows do
        table.sort(by_row[r], function(a, b)
            return a.col < b.col
        end)
    end

    local function starts_for_row(r)
        local m = {}
        for _, p in ipairs(by_row[r]) do
            m[p.col] = p
        end
        return m
    end

    local function build_cell(block, cw, ch, zone_tag, col_span, prow, pcol)
        ctx.placement_row = prow
        ctx.placement_col = pcol
        local col = VerticalGroup:new{ align = "center" }
        if not block then
            table.insert(col, VerticalSpan:new{ width = 1 })
        else
            local content_w = math.max(0, cw - 2 * card_pad)
            local content_h = math.max(0, ch - 2 * card_pad)
            local span = tonumber(col_span) or 1
            if span ~= 2 and span ~= 3 then
                span = 1
            end
            ctx.col_span = span
            ctx.cell_w = cw
            ctx.cell_h = ch
            ctx.cell_max_w = math.max(LAYOUT.cell_content_min_px, content_w)
            ctx.cell_max_h = math.max(LAYOUT.cell_content_min_px, content_h)
            ctx.zone_index = zone_tag
            local card_palette = CardTheme.palette_for_placement(block.type, block.params or {})
            ctx.card_palette = card_palette
            local w = Registry.build(block, ctx)
            if w then
                local holder = SlotFillHolder:new{
                    inner_w = content_w,
                    inner_h = content_h,
                    w,
                }
                table.insert(col, SleepWidgetCard:new{
                    B_SETT = B_SETT,
                    radius = card_r,
                    pad_h = card_pad,
                    pad_v = card_pad,
                    palette = card_palette,
                    holder,
                })
            else
                table.insert(col, VerticalSpan:new{ width = 1 })
            end
        end
        local inner = FrameContainer:new{
            background = nil,
            bordersize = 0,
            padding = 0,
            margin = 0,
            VerticalGroup:new{
                align = "center",
                col,
            },
        }
        return CellSlot:new{
            slot_w = cw,
            slot_h = ch,
            inner,
        }
    end

    local rows_group = VerticalGroup:new{ align = "center" }
    for r = 1, grid_rows do
        local row_group = HorizontalGroup:new{ align = "center" }
        local starts = starts_for_row(r)
        local col = 1
        while col <= grid_cols do
            local p = starts[col]
            if p then
                local span = p.span or 1
                local mw = LayoutSpec.merged_span_width(slot_w, gutter_x, span)
                local block = { type = p.type, params = p.params }
                local zone_tag = r * LAYOUT.zone_tag_row_multiplier + p.col
                table.insert(row_group, build_cell(block, mw, row_h, zone_tag, span, r, p.col))
                col = col + span
            else
                local zone_tag = r * LAYOUT.zone_tag_row_multiplier + col
                table.insert(row_group, build_cell(nil, slot_w, row_h, zone_tag, 1, r, col))
                col = col + 1
            end
            if col <= grid_cols then
                table.insert(row_group, HorizontalSpan:new{ width = gutter_x })
            end
        end
        table.insert(rows_group, row_group)
        if r < grid_rows then
            table.insert(rows_group, VerticalSpan:new{ width = gutter_y })
        end
    end

    local h_outer_left = HorizontalSpan:new{ width = edge_ml }
    local h_outer_right = HorizontalSpan:new{ width = edge_mr }

    local h_padded = HorizontalGroup:new{
        align = "center",
        h_outer_left,
        rows_group,
        h_outer_right,
    }

    local root_parts = VerticalGroup:new{
        align = "center",
        VerticalSpan:new{ width = edge_mt },
        h_padded,
        VerticalSpan:new{ width = edge_mb },
    }
    return FrameContainer:new{
        background = nil,
        bordersize = 0,
        margin = 0,
        padding = 0,
        root_parts,
    }
end

return GridComposer

local Device = require("device")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local OverlapGroup = require("ui/widget/overlapgroup")
local CenterContainer = require("ui/widget/container/centercontainer")
local Screen = Device.screen
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local FrameStyle = require("banner.frame_style")
local ReadingStats = require("data.reading_stats")
local WeekWindow = require("data.week_window")
local WidgetSpan = require("banner.widget_span")
local WLetters = require("banner.widgets.activity.week_day_letters")
local ActivityRings = require("banner.widgets.activity.activity_rings")
local RL = require("banner.widgets.activity.rings_layout")
local JM = require("banner.widgets.activity.journal_math")

local _ = require("l10n").gettext

local M = {}

local function decorate_palette_goal_rings(pal)
    pal.ring_minutes_track = pal.ring_minutes_track or pal.progress_track
    pal.ring_minutes_fill = pal.ring_minutes_fill or pal.progress_fill
    pal.ring_minutes_fill_complete = pal.ring_minutes_fill_complete or pal.ring_minutes_fill
    pal.ring_pages_track = pal.ring_pages_track or pal.progress_track
    pal.ring_pages_fill = pal.ring_pages_fill or pal.progress_fill
    pal.ring_pages_fill_complete = pal.ring_pages_fill_complete or pal.ring_pages_fill
end

local function ring_fill_for_progress(pal, kind, frac)
    local f = tonumber(frac) or 0
    if f >= 1 then
        if kind == "minutes" then
            return pal.ring_minutes_fill_complete or pal.ring_minutes_fill
        end
        return pal.ring_pages_fill_complete or pal.ring_pages_fill
    end
    if kind == "minutes" then
        return pal.ring_minutes_fill
    end
    return pal.ring_pages_fill
end

local function cmp_ymd(y, m, d, y2, m2, d2)
    if y ~= y2 then
        return y < y2 and -1 or 1
    end
    if m ~= m2 then
        return m < m2 and -1 or 1
    end
    if d ~= d2 then
        return d < d2 and -1 or 1
    end
    return 0
end

local function date_key(y, m, d)
    return string.format("%04d-%02d-%02d", y, m, d)
end

function M.build(params, ctx)
    params = params or {}
    local max_w = ctx.cell_max_w or 100
    local pal = ctx.card_palette or FrameStyle.card_colors_light()
    decorate_palette_goal_rings(pal)

    local week_start = params.week_start == "sun" and "sun" or "mon"
    local now = os.date("*t")
    local days = WeekWindow.seven_days(now, week_start)

    local af = WeekWindow.anchor_midnight_fields(now, week_start)
    local start_unix = os.time({
        year = af.year,
        month = af.month,
        day = af.day,
        hour = 0,
        min = 0,
        sec = 0,
        isdst = af.isdst,
    })
    local last = days[7]
    local end_unix = os.time({
        year = last.year,
        month = last.month,
        day = last.day + 1,
        hour = 0,
        min = 0,
        sec = 0,
        isdst = af.isdst,
    })

    local sec_today, sec_err = ReadingStats.total_seconds_today()
    local pages_today, pages_err = ReadingStats.pages_read_today()
    local minutes = 0
    if type(sec_today) == "number" then
        minutes = math.floor(sec_today / 60)
    end
    if type(pages_today) ~= "number" then
        pages_today = 0
    end

    local goal_minutes = math.max(0, math.floor(tonumber(params.daily_goal_minutes) or 0))
    local goal_pages = math.max(0, math.floor(tonumber(params.daily_goal_pages) or 0))

    local col = VerticalGroup:new{ align = "left" }

    local function w_tb(o)
        o.bgcolor = pal.fill
        return TextBoxWidget:new(o)
    end

    local gap = Screen:scaleBySize(3)
    local cell_w = math.max(24, math.floor((max_w - gap * 6) / 7))
    local title_reserve = Screen:scaleBySize(20)
    local footer_reserve = Screen:scaleBySize(22)
    local span_reserve = Screen:scaleBySize(14)
    local max_cell_h = tonumber(ctx.cell_max_h) or 320
    local ring_budget_h = math.max(24, max_cell_h - title_reserve - footer_reserve - span_reserve)
    local ring_size = math.max(24, math.min(cell_w - Screen:scaleBySize(1), ring_budget_h))
    --- Same horizontal inset as `rings_w.overlap_offset` in the first column — aligns title with ring artwork.
    local ring_inset = math.max(0, math.floor((cell_w - ring_size) / 2))

    local title_text = (type(params.title) == "string" and params.title ~= "") and params.title
        or _("Reading activity")

    table.insert(col, HorizontalGroup:new{
        align = "bottom",
        HorizontalSpan:new{ width = ring_inset },
        w_tb{
            text = title_text,
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(13, ctx)),
            width = math.max(24, max_w - ring_inset),
            fgcolor = pal.text_primary,
            alignment = "left",
            bold = true,
        },
    })
    table.insert(col, VerticalSpan:new{ width = Screen:scaleBySize(4) })

    local stat_map = ReadingStats.seconds_sum_by_local_date(start_unix, end_unix)
    if stat_map == nil then
        table.insert(col, w_tb{
            text = _("No statistics"),
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(12, ctx)),
            width = max_w,
            fgcolor = pal.text_secondary,
            alignment = "center",
        })
        return col
    end

    local pages_map = ReadingStats.pages_sum_by_local_date(start_unix, end_unix)
    if pages_map == nil then
        pages_map = {}
    end

    if not JM.has_active_goal(goal_minutes, goal_pages) then
        table.insert(col, w_tb{
            text = _("No goals set"),
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(12, ctx)),
            width = max_w,
            fgcolor = pal.text_secondary,
            alignment = "center",
        })
        return col
    end

    local dual = goal_minutes > 0 and goal_pages > 0

    --- Inner hole radius for letters (single ring: inside outer track; dual: inside inner track).
    local stroke_geom, ring_gap, r_out_geom, r_in_geom = RL.ring_geometry(ring_size, dual)
    local hole_r = (dual and r_in_geom) and math.max(3, r_in_geom - stroke_geom)
        or math.max(3, r_out_geom - stroke_geom)
    local inner_d = 2 * hole_r
    local letter_pt = math.max(
        7,
        math.min(
            math.floor(inner_d * 0.36 + 0.5),
            math.floor(ring_size * 0.26 + 0.5)
        )
    )
    local letter_face = Font:getFace("cfont", WidgetSpan.scaled_font_size(letter_pt, ctx))

    local function ring_for_levels(level_minutes, level_pages)
        local rings_opts = {
            size = ring_size,
            bg_color = pal.fill,
            two_rings = dual,
        }
        local fm = RL.progress_draw_frac(level_minutes, goal_minutes)
        local fp = RL.progress_draw_frac(level_pages, goal_pages)
        if dual then
            rings_opts.pct_outer = fm
            rings_opts.pct_inner = fp
            rings_opts.c_track_outer = pal.ring_minutes_track
            rings_opts.c_fill_outer = ring_fill_for_progress(pal, "minutes", fm)
            rings_opts.c_track_inner = pal.ring_pages_track
            rings_opts.c_fill_inner = ring_fill_for_progress(pal, "pages", fp)
        elseif goal_minutes > 0 then
            rings_opts.pct_outer = fm
            rings_opts.pct_inner = 0
            rings_opts.c_track_outer = pal.ring_minutes_track
            rings_opts.c_fill_outer = ring_fill_for_progress(pal, "minutes", fm)
            rings_opts.c_track_inner = pal.ring_pages_track
            rings_opts.c_fill_inner = pal.ring_pages_fill
        else
            rings_opts.pct_outer = fp
            rings_opts.pct_inner = 0
            rings_opts.c_track_outer = pal.ring_pages_track
            rings_opts.c_fill_outer = ring_fill_for_progress(pal, "pages", fp)
            rings_opts.c_track_inner = pal.ring_pages_track
            rings_opts.c_fill_inner = pal.ring_pages_fill
        end
        return ActivityRings:new(rings_opts)
    end

    local function ring_empty_muted_track()
        return ActivityRings:new{
            size = ring_size,
            bg_color = pal.fill,
            two_rings = false,
            pct_outer = 0,
            pct_inner = 0,
            c_track_outer = pal.progress_track,
            c_fill_outer = pal.progress_track,
            c_track_inner = pal.progress_track,
            c_fill_inner = pal.progress_track,
        }
    end

    local row = HorizontalGroup:new{ align = "center" }

    local function ring_for_today()
        return ring_for_levels(minutes, pages_today)
    end

    for i = 1, 7 do
        if i > 1 then
            table.insert(row, HorizontalSpan:new{ width = gap })
        end
        local d = days[i]
        local dk = date_key(d.year, d.month, d.day)
        local day_sec = tonumber(stat_map[dk]) or 0
        local cmp = cmp_ymd(d.year, d.month, d.day, now.year, now.month, now.day)
        local letter = WLetters.letter_for_wday(d.wday)

        local og = OverlapGroup:new{
            dimen = Geom:new{ x = 0, y = 0, w = cell_w, h = cell_w },
            allow_mirroring = false,
        }

        local rings_w
        local fg_letter = pal.text_primary

        if cmp == 0 then
            rings_w = ring_for_today()
            fg_letter = pal.text_primary
        elseif cmp > 0 then
            rings_w = ring_empty_muted_track()
            fg_letter = pal.text_secondary
        else
            local dm = math.floor(day_sec / 60)
            local dp = tonumber(pages_map[dk]) or 0
            if dm <= 0 and dp <= 0 then
                rings_w = ring_empty_muted_track()
                fg_letter = pal.text_secondary
            else
                rings_w = ring_for_levels(dm, dp)
                fg_letter = pal.text_primary
            end
        end

        local ox = math.max(0, math.floor((cell_w - ring_size) / 2))
        rings_w.overlap_offset = { ox, ox }

        table.insert(og, rings_w)
        local tw = TextWidget:new{
            text = letter,
            face = letter_face,
            bold = true,
            fgcolor = fg_letter,
            padding = 0,
        }
        local cc = CenterContainer:new{
            dimen = Geom:new{ x = 0, y = 0, w = cell_w, h = cell_w },
        }
        table.insert(cc, tw)
        table.insert(og, cc)

        table.insert(row, og)
    end

    table.insert(col, row)
    table.insert(col, VerticalSpan:new{ width = Screen:scaleBySize(4) })

    local rem_m = goal_minutes > 0 and math.max(0, goal_minutes - minutes) or nil
    local rem_p = goal_pages > 0 and math.max(0, goal_pages - pages_today) or nil

    local footer_text
    if rem_m ~= nil and rem_p ~= nil then
        local part_a = string.format(_("%d min to goal"), rem_m)
        local part_b = string.format(_("%d pages to goal"), rem_p)
        footer_text = string.format(_("%s · %s"), part_a, part_b)
    elseif rem_m ~= nil then
        footer_text = string.format(_("%d min to goal"), rem_m)
    else
        footer_text = string.format(_("%d pages to goal"), rem_p or 0)
    end

    table.insert(col, w_tb{
        text = footer_text,
        face = Font:getFace("cfont", WidgetSpan.scaled_font_size(11, ctx)),
        width = max_w,
        fgcolor = pal.text_primary,
        alignment = "center",
    })

    return col
end

return M

local Device = require("device")
local Font = require("ui/font")
local Screen = Device.screen
local TextBoxWidget = require("ui/widget/textboxwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local JM = require("banner.widgets.activity.journal_math")
local Journal = require("banner.widgets.activity.journal")
local WidgetSpan = require("banner.widget_span")
local FrameStyle = require("banner.frame_style")
local ActivityRings = require("banner.widgets.activity.activity_rings")
local RL = require("banner.widgets.activity.rings_layout")
local ReadingStats = require("data.reading_stats")

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

function M.build(params, ctx)
    local max_w = ctx.cell_max_w or 100
    local pal = ctx.card_palette or FrameStyle.card_colors_light()
    decorate_palette_goal_rings(pal)

    local sec, sec_err = ReadingStats.total_seconds_today()
    local pages, pages_err = ReadingStats.pages_read_today()
    local minutes = 0
    if type(sec) == "number" then
        minutes = math.floor(sec / 60)
    end
    if type(pages) ~= "number" then
        pages = 0
    end

    local goal_minutes = math.max(0, math.floor(tonumber(params.daily_goal_minutes) or 0))
    local goal_pages = math.max(0, math.floor(tonumber(params.daily_goal_pages) or 0))
    local no_stats = sec_err ~= nil and pages_err ~= nil
    local met = not no_stats and JM.targets_met_today(minutes, pages, goal_minutes, goal_pages)
    local streak = 0
    if not no_stats then
        streak = Journal.slot_streak_from_build(params, ctx, minutes, pages)
    end

    local col = VerticalGroup:new{ align = "left" }

    local function goal_tb(o)
        o.bgcolor = pal.fill
        return TextBoxWidget:new(o)
    end

    if no_stats then
        table.insert(col, goal_tb{
            text = _("No statistics"),
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(12, ctx)),
            width = max_w,
            fgcolor = pal.text_secondary,
            alignment = "left",
        })
        return col
    end

    local has_goal = JM.has_active_goal(goal_minutes, goal_pages)

    if not has_goal then
        table.insert(col, goal_tb{
            text = _("No goals set"),
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(12, ctx)),
            width = max_w,
            fgcolor = pal.text_secondary,
            alignment = "left",
        })
        return col
    end

    local dual = goal_minutes > 0 and goal_pages > 0
    local reserve_text = dual and Screen:scaleBySize(64) or Screen:scaleBySize(48)
    if streak > 0 then
        reserve_text = reserve_text + Screen:scaleBySize(22)
    end
    if met then
        reserve_text = reserve_text + Screen:scaleBySize(28)
    end
    local max_h = math.max(40, tonumber(ctx.cell_max_h) or max_w)
    local S = RL.rings_square_side(max_w, max_h, reserve_text)

    local frac_minutes = RL.progress_draw_frac(minutes, goal_minutes)
    local frac_pages = RL.progress_draw_frac(pages, goal_pages)

    local rings_opts = {
        size = S,
        bg_color = pal.fill,
        two_rings = dual,
        flush_ring_left = true,
    }

    if dual then
        rings_opts.pct_outer = frac_minutes
        rings_opts.pct_inner = frac_pages
        rings_opts.c_track_outer = pal.ring_minutes_track
        rings_opts.c_fill_outer = ring_fill_for_progress(pal, "minutes", frac_minutes)
        rings_opts.c_track_inner = pal.ring_pages_track
        rings_opts.c_fill_inner = ring_fill_for_progress(pal, "pages", frac_pages)
    elseif goal_minutes > 0 then
        rings_opts.pct_outer = frac_minutes
        rings_opts.pct_inner = 0
        rings_opts.c_track_outer = pal.ring_minutes_track
        rings_opts.c_fill_outer = ring_fill_for_progress(pal, "minutes", frac_minutes)
        rings_opts.c_track_inner = pal.ring_pages_track
        rings_opts.c_fill_inner = pal.ring_pages_fill
    else
        rings_opts.pct_outer = frac_pages
        rings_opts.pct_inner = 0
        rings_opts.c_track_outer = pal.ring_pages_track
        rings_opts.c_fill_outer = ring_fill_for_progress(pal, "pages", frac_pages)
        rings_opts.c_track_inner = pal.ring_pages_track
        rings_opts.c_fill_inner = pal.ring_pages_fill
    end

    table.insert(col, ActivityRings:new(rings_opts))

    table.insert(col, VerticalSpan:new{ width = Screen:scaleBySize(6) })

    local line_face = Font:getFace("cfont", WidgetSpan.scaled_font_size(12, ctx))

    if goal_minutes > 0 then
        table.insert(col, goal_tb{
            text = RL.xy_line(minutes, goal_minutes, _("MIN")),
            face = line_face,
            width = max_w,
            fgcolor = ring_fill_for_progress(pal, "minutes", frac_minutes),
            alignment = "left",
        })
    end

    if goal_pages > 0 then
        table.insert(col, goal_tb{
            text = RL.xy_line(pages, goal_pages, _("PAGES")),
            face = line_face,
            width = max_w,
            fgcolor = ring_fill_for_progress(pal, "pages", frac_pages),
            alignment = "left",
        })
    end

    if streak > 0 then
        table.insert(col, VerticalSpan:new{ width = Screen:scaleBySize(10) })
        table.insert(col, goal_tb{
            text = _("Streak") .. " · " .. tostring(streak) .. " 🔥",
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(11, ctx)),
            width = max_w,
            fgcolor = pal.text_primary,
            alignment = "left",
        })
    end

    if met then
        table.insert(col, VerticalSpan:new{ width = Screen:scaleBySize(8) })
        if goal_minutes > 0 and goal_pages > 0 then
            table.insert(col, goal_tb{
                text = _("Daily goals reached") .. " · ✓",
                face = Font:getFace("cfont", WidgetSpan.scaled_font_size(13, ctx)),
                width = max_w,
                fgcolor = pal.text_primary,
                alignment = "left",
                bold = true,
            })
        elseif goal_minutes > 0 then
            table.insert(col, goal_tb{
                text = _("Daily time goal reached") .. " · ✓",
                face = Font:getFace("cfont", WidgetSpan.scaled_font_size(13, ctx)),
                width = max_w,
                fgcolor = pal.text_primary,
                alignment = "left",
                bold = true,
            })
        else
            table.insert(col, goal_tb{
                text = _("Daily pages goal reached") .. " · ✓",
                face = Font:getFace("cfont", WidgetSpan.scaled_font_size(13, ctx)),
                width = max_w,
                fgcolor = pal.text_primary,
                alignment = "left",
                bold = true,
            })
        end
    end

    return col
end

return M

local Device = require("device")
local Font = require("ui/font")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ImageWidget = require("ui/widget/imagewidget")
local Screen = Device.screen
local RoundedProgressBar = require("banner.rounded_progress_bar")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local ETA = require("banner.widgets.reading_now.eta")
local FrameStyle = require("banner.frame_style")
local WidgetSpan = require("banner.widget_span")

local _ = require("l10n").gettext

local M = {}

local function avg_page_seconds_fallback(ui)
    if not ui or not ui.doc_settings or not ui.doc_settings.data then
        return nil
    end
    local d = ui.doc_settings.data
    local secs = tonumber(d.stats_sec_per_page_average) or tonumber(d.sec_per_page)
    if secs and secs > 0 then
        return secs
    end
    return nil
end

local function eta_minutes_for_ui(ui)
    local canonical = ETA.remaining_minutes_best_effort(ui)
    if canonical ~= nil then
        return canonical
    end
    local sp = avg_page_seconds_fallback(ui)
    if not sp or sp <= 0 or not ui or not ui.document then
        return nil
    end
    local page = 1
    if ui.view and ui.view.state and tonumber(ui.view.state.page) then
        page = math.floor(ui.view.state.page)
    end
    local total = ETA.total_pages_best_effort(ui)
    if total <= 0 then
        return nil
    end
    page = math.max(1, math.min(page, total))
    local remaining = math.max(0, total - page)
    return math.ceil(remaining * sp / 60)
end

local function cover_path_best_effort(ui)
    if not ui or not ui.document then
        return nil
    end
    local doc = ui.document

    local try_seq = {}

    table.insert(try_seq, function()
        if type(doc.getCoverFile) ~= "function" then
            return nil
        end
        local ok, p = pcall(function()
            return doc:getCoverFile()
        end)
        if ok and type(p) == "string" and p ~= "" then
            return p
        end
        return nil
    end)

    table.insert(try_seq, function()
        if type(ui.getCoverFile) ~= "function" then
            return nil
        end
        local ok, p = pcall(function()
            return ui:getCoverFile()
        end)
        if ok and type(p) == "string" and p ~= "" then
            return p
        end
        return nil
    end)

    table.insert(try_seq, function()
        local pinfo = ui.doc_props or {}
        if type(pinfo.cover_path) == "string" and pinfo.cover_path ~= "" then
            return pinfo.cover_path
        end
        return nil
    end)

    for _, fn in ipairs(try_seq) do
        local ok, path = pcall(fn)
        if ok and path then
            return path
        end
    end
    return nil
end

function M.build(params, ctx)
    params = params or {}
    local max_w = ctx.cell_max_w or 100
    local text_w = max_w
    local pal = ctx.card_palette or FrameStyle.card_colors_light()
    local ui = ctx.ui_inst

    if not ui or not ui.document then
        local empty = VerticalGroup:new{ align = "left" }
        table.insert(empty, TextBoxWidget:new{
            text = _("No book open"),
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(14, ctx)),
            width = max_w,
            fgcolor = pal.text_secondary,
            alignment = "center",
        })
        return empty
    end

    local doc_props = ui.doc_props or {}
    local title = doc_props.display_title or doc_props.title or ""
    local author = doc_props.authors or ""
    if type(author) == "string" and author:find("\n") then
        local util = require("util")
        local authors = util.splitToArray(author, "\n")
        author = authors[1] or author
    end

    local page = 1
    local total = 1
    if ui.view and ui.view.state and ui.view.state.page then
        page = ui.view.state.page
    end
    local doc_settings = ui.doc_settings and ui.doc_settings.data or {}
    total = tonumber(doc_settings.doc_pages) or 1
    if total <= 0 then
        total = 1
    end
    page = math.max(1, math.min(page, total))

    local pct = math.max(0, math.min(1, page / total))
    local pct_txt = string.format("%d%%", math.floor(pct * 100 + 0.5))

    if title == "" then
        title = _("Untitled")
    end

    local show_cover = params.show_cover == true
    local cover_w = 0
    local cover_file
    if show_cover then
        cover_file = cover_path_best_effort(ui)
        if cover_file then
            cover_w = math.max(Screen:scaleBySize(48), math.floor(max_w * 0.26 + 0.5))
            text_w = math.max(40, max_w - cover_w - Screen:scaleBySize(6))
        else
            show_cover = false
        end
    end

    local pct_widget = TextWidget:new{
        text = pct_txt,
        face = Font:getFace("cfont", WidgetSpan.scaled_font_size(14, ctx)),
        fgcolor = pal.text_secondary,
        padding = 0,
    }
    local title_width = math.max(40, text_w - pct_widget:getSize().w - Screen:scaleBySize(4))
    local title_box = TextBoxWidget:new{
        text = title,
        face = Font:getFace("cfont", WidgetSpan.scaled_font_size(16, ctx)),
        width = title_width,
        fgcolor = pal.text_primary,
        bold = true,
    }
    local head = HorizontalGroup:new{}
    table.insert(head, title_box)
    local span_w = math.max(0, text_w - title_box:getSize().w - pct_widget:getSize().w)
    table.insert(head, HorizontalSpan:new{ width = span_w })
    table.insert(head, pct_widget)

    local text_col = VerticalGroup:new{ align = "left" }
    table.insert(text_col, head)

    if author ~= "" then
        table.insert(text_col, VerticalSpan:new{ width = Screen:scaleBySize(2) })
        table.insert(text_col, TextBoxWidget:new{
            text = author,
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(13, ctx)),
            width = text_w,
            fgcolor = pal.text_secondary,
        })
    end

    local eta_min = eta_minutes_for_ui(ui)
    table.insert(text_col, VerticalSpan:new{ width = Screen:scaleBySize(4) })
    if eta_min ~= nil then
        table.insert(text_col, TextBoxWidget:new{
            text = _("ETA") .. ": " .. tostring(math.max(0, math.floor(eta_min))) .. " " .. _("min"),
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(12, ctx)),
            width = text_w,
            fgcolor = pal.text_secondary,
            alignment = "left",
        })
    else
        table.insert(text_col, TextBoxWidget:new{
            text = _("ETA") .. ": " .. _("—"),
            face = Font:getFace("cfont", WidgetSpan.scaled_font_size(12, ctx)),
            width = text_w,
            fgcolor = pal.text_secondary,
            alignment = "left",
        })
    end

    local prog_h = Screen:scaleBySize(14)
    local prog_radius = math.max(Screen:scaleBySize(4), math.floor(prog_h / 3))

    local upper = HorizontalGroup:new{ align = "top" }
    if show_cover and cover_file and cover_w > 0 then
        local ok_cover, iw = pcall(function()
            return ImageWidget:new{
                file = cover_file,
                width = cover_w,
                height = cover_w,
                scale_factor = 0,
            }
        end)
        if ok_cover and iw then
            table.insert(upper, iw)
            table.insert(upper, HorizontalSpan:new{ width = Screen:scaleBySize(6) })
        end
    end
    table.insert(upper, text_col)

    local col = VerticalGroup:new{ align = "left" }
    table.insert(col, upper)
    table.insert(col, VerticalSpan:new{ width = Screen:scaleBySize(6) })
    table.insert(col, RoundedProgressBar:new{
        width = max_w,
        height = prog_h,
        percentage = pct,
        margin_v = 0,
        margin_h = 0,
        radius = prog_radius,
        bgcolor = pal.progress_track,
        fillcolor = pal.progress_fill,
    })

    return col
end

return M

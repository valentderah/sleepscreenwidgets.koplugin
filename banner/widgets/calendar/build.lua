local Device = require("device")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local OverlapGroup = require("ui/widget/overlapgroup")
local CenterContainer = require("ui/widget/container/centercontainer")
local Screen = Device.screen
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")

local FrameStyle = require("banner.frame_style")
local Registry = require("banner.widgets.registry")
local WidgetSpan = require("banner.widget_span")
local MonthGrid = require("banner.widgets.calendar.month_grid")
local MonthRowWindow = require("banner.widgets.calendar.month_row_window")
local MonthDateFit = require("banner.widgets.calendar.month_date_fit")
local RoundedCellBg = require("banner.widgets.calendar.rounded_cell_bg")

local M = {}

--- Column headers: index = grid column 1..7 (Sun-first or Mon-first).
local DOW_SUN_FIRST = { "S", "M", "T", "W", "T", "F", "S" }
local DOW_MON_FIRST = { "M", "T", "W", "T", "F", "S", "S" }

local function build_day(params, ctx, pal, max_w)
    params = params or {}
    local month_fmt = (type(params.month_format) == "string" and params.month_format ~= "")
        and params.month_format or "%b"
    local day_num = tonumber(os.date("%d")) or 1
    local month_str = string.upper(os.date(month_fmt))
    local day_size = params.day_size or 32
    local month_size = params.month_size or 14

    local col = VerticalGroup:new{ align = "center" }
    table.insert(col, TextBoxWidget:new{
        text = month_str,
        face = Font:getFace("cfont", WidgetSpan.scaled_font_size(month_size, ctx)),
        width = max_w,
        fgcolor = pal.text_secondary,
        bgcolor = pal.fill,
        alignment = "center",
        bold = true,
    })
    table.insert(col, VerticalSpan:new{ width = Screen:scaleBySize(4) })
    table.insert(col, TextBoxWidget:new{
        text = tostring(day_num),
        face = Font:getFace("cfont", WidgetSpan.scaled_font_size(day_size, ctx)),
        width = max_w,
        fgcolor = pal.text_primary,
        bgcolor = pal.fill,
        alignment = "center",
        bold = true,
    })
    return col
end

--- Единая геометрия слота даты: у всех колонок одинаковый OverlapGroup (как у «сегодня»),
--- иначе смесь TextBoxWidget / OverlapGroup смещает цифры по горизонтали в ряду.
local function month_grid_date_slot(cell_w, cell_h, face_dates, day_text, is_today, fg, pal)
    local og = OverlapGroup:new{
        dimen = Geom:new{ x = 0, y = 0, w = cell_w, h = cell_h },
        allow_mirroring = false,
    }
    if is_today then
        --- Круг только внутри слота даты: на широких ячейках (span≥2) не раздувать диаметр за счёт inner_w.
        local inset = Screen:scaleBySize(2)
        local diam = math.min(cell_w - 2 * inset, cell_h - 2 * inset)
        diam = math.max(Screen:scaleBySize(14), math.floor(diam))
        local circle_x = math.max(0, math.floor((cell_w - diam) / 2))
        local circle_y = math.max(0, math.floor((cell_h - diam) / 2))
        table.insert(og, RoundedCellBg:new{
            width = diam,
            height = diam,
            radius = math.floor(diam / 2),
            bgcolor = pal.calendar_accent,
            overlap_offset = { circle_x, circle_y },
        })
    end
    local cc = CenterContainer:new{
        dimen = Geom:new{ x = 0, y = 0, w = cell_w, h = cell_h },
    }
    table.insert(cc, TextWidget:new{
        text = day_text,
        face = face_dates,
        fgcolor = fg,
        bold = true,
        padding = 0,
    })
    table.insert(og, cc)
    return og
end

local function build_month(params, ctx, pal, max_w)
    params = params or {}
    local week_start = params.week_start == "sun" and "sun" or "mon"
    local dow_letters = week_start == "sun" and DOW_SUN_FIRST or DOW_MON_FIRST
    local now = os.date("*t")
    local grid = MonthGrid.cell_grid(now.year, now.month, now.year, now.month, now.day, week_start)

    local cell_w = math.max(8, math.floor(max_w / 7))
    --- Ширина сетки 7×cell_w ≤ max_w; заголовок месяца по той же ширине — левый край как у первого столбца.
    local grid_w = cell_w * 7
    local cell_sz, _ = MonthDateFit.pick_date_cell_sz_and_pad(cell_w, ctx, function(n)
        return Screen:scaleBySize(n)
    end)
    local fs_cell = WidgetSpan.scaled_font_size(cell_sz, ctx)
    local cell_h = math.max(Screen:scaleBySize(16), math.floor(fs_cell * 1.45))

    --- Заголовок месяца — отдельный логический размер (params.month_size), не размер ячейки даты.
    local month_title_sz = tonumber(params.month_size) or 20
    local fs_month = WidgetSpan.scaled_font_size(month_title_sz, ctx)

    --- Отступы от доли высоты шрифта дат: компактнее, в окно по высоте влезает больше рядов.
    local gap_after_title = math.max(Screen:scaleBySize(2), math.ceil(fs_cell * 0.18))
    local gap_after_dow = math.max(Screen:scaleBySize(1), math.ceil(fs_cell * 0.12))
    local gap_between_date_rows = math.max(0, math.ceil(fs_cell * 0.06))

    local title_line_h = math.max(Screen:scaleBySize(15), math.ceil(fs_month * 1.3))
    local dow_line_h = math.max(Screen:scaleBySize(12), math.ceil(fs_cell * 1.22))
    local H_chrome = title_line_h + gap_after_title + dow_line_h + gap_after_dow

    local cell_max_h = tonumber(ctx.cell_max_h)
    if cell_max_h == nil or cell_max_h <= 0 then
        cell_max_h = 99999
    end
    local B_SETT = ctx and ctx.B_SETT
    local vertical_slack = Screen:scaleBySize(2) + math.ceil(FrameStyle.card_border_width(B_SETT))
    local H_dates = math.max(0, cell_max_h - H_chrome - vertical_slack)
    --- TextWidget в ячейках даёт меньший «хвост» по baseline, чем TextBoxWidget — можно чуть ужать оценку строки.
    local date_row_fit_h = cell_h + math.max(Screen:scaleBySize(1), math.ceil(fs_cell * 0.1))
    local k_fit = MonthRowWindow.max_date_rows_fit(H_dates, date_row_fit_h, gap_between_date_rows)

    local r_min, r_max = MonthRowWindow.occupied_row_range(grid)
    local need_rows = r_max - r_min + 1
    local r_today = MonthRowWindow.today_row_index(grid)

    local start_row, end_row
    if need_rows <= k_fit then
        start_row = r_min
        end_row = r_max
    else
        local k_show = math.max(1, math.min(k_fit, need_rows, 6))
        start_row = MonthRowWindow.visible_row_start(r_min, r_max, r_today, k_show)
        end_row = start_row + k_show - 1
    end

    local title = string.upper(os.date("%B"))
    local col = VerticalGroup:new{ align = "left" }
    table.insert(col, TextBoxWidget:new{
        text = title,
        face = Font:getFace("cfont", fs_month),
        width = grid_w,
        fgcolor = pal.calendar_accent,
        bgcolor = pal.fill,
        alignment = "left",
        bold = true,
    })
    table.insert(col, VerticalSpan:new{ width = gap_after_title })

    local face_dates = Font:getFace("cfont", fs_cell)
    local dow_row = HorizontalGroup:new{ align = "center" }
    for c = 1, 7 do
        table.insert(dow_row, TextBoxWidget:new{
            text = dow_letters[c],
            face = face_dates,
            width = cell_w,
            fgcolor = pal.calendar_muted,
            bgcolor = pal.fill,
            alignment = "center",
            bold = true,
        })
    end
    table.insert(col, dow_row)
    table.insert(col, VerticalSpan:new{ width = gap_after_dow })

    for r = start_row, end_row do
        local row = HorizontalGroup:new{ align = "center" }
        for c = 1, 7 do
            local cell = grid[r][c]
            local weekend = (week_start == "sun") and (c == 1 or c == 7) or (c == 6 or c == 7)
            local day_text
            local is_today
            local fg
            if cell.day == nil then
                day_text = ""
                is_today = false
                fg = pal.text_primary
            elseif cell.is_today then
                day_text = tostring(cell.day)
                is_today = true
                fg = pal.calendar_on_accent
            else
                day_text = tostring(cell.day)
                is_today = false
                fg = weekend and pal.calendar_muted or pal.text_primary
            end
            table.insert(row, month_grid_date_slot(cell_w, cell_h, face_dates, day_text, is_today, fg, pal))
        end
        table.insert(col, row)
        if r < end_row then
            table.insert(col, VerticalSpan:new{ width = gap_between_date_rows })
        end
    end

    return col
end

function M.build(params, ctx)
    params = Registry.normalize_widget_params("calendar", params or {})
    local max_w = ctx.cell_max_w or 100
    local pal = ctx.card_palette or FrameStyle.card_colors_light()
    local layout = params.calendar_layout == "month" and "month" or "day"
    if layout == "month" then
        return build_month(params, ctx, pal, max_w)
    end
    return build_day(params, ctx, pal, max_w)
end

return M

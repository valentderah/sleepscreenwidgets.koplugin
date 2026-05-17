--[[ Shared text helpers for sleep banner widgets (KOReader). ]]
local BookInfo = require("apps/filemanager/filemanagerbookinfo")
local datetime = require("datetime")
local TextBoxWidget = require("ui/widget/textboxwidget")
local TextWidget = require("ui/widget/textwidget")
local util = require("util")
local VerticalGroup = require("ui/widget/verticalgroup")

local BannerText = {}

function BannerText.expand_string(ui_for_bookinfo, pattern, last_file)
    if ui_for_bookinfo and ui_for_bookinfo.bookinfo then
        return ui_for_bookinfo.bookinfo:expandString(pattern, last_file)
    end
    return BookInfo:expandString(pattern, last_file)
end

function BannerText.addQuotesIfReq(text)
    if not text or text == "" then
        return text
    end
    local chars = util.splitToChars(text)
    local first_char = chars[1]
    local last_char = chars[#chars]
    local control = {
        { "'", "'" }, { '"', '"' }, { "“", "”" },
        { "‘", "’" }, { "«", "»" }, { "„", "“" },
    }
    local quotes_found = false
    for _, quotes in ipairs(control) do
        if first_char == quotes[1] and last_char == quotes[2] then
            quotes_found = true
            break
        end
    end
    if not quotes_found then
        return "“" .. text .. "”"
    end
    return text
end

function BannerText.parseFooterText(text, index, Sidecar)
    if not text or not index or text == "" then
        return text
    end

    local hl_array = Sidecar and Sidecar:readSetting("annotations")
    hl_array = hl_array and hl_array[index] or {}
    local hl_chapter = hl_array.chapter or "N/A"
    local hl_pageno = Sidecar and Sidecar:isTrue("pagemap_use_page_labels") and hl_array.pageref or hl_array.pageno or "N/A"

    local doc_props = Sidecar and Sidecar:readSetting("doc_props") or {}
    local bk_author = doc_props.authors or "N/A"
    local bk_title = doc_props.title or "N/A"

    local hl_date, yr, mth, dy
    local date_and_time = hl_array.datetime and util.splitToArray(hl_array.datetime, "%s+", false) or {}

    hl_date = date_and_time[1] or ""
    yr, mth, dy = hl_date:match("(%d+)-(%d+)-(%d+)")
    local month_abbr = yr and mth and dy and os.date("%b", os.time{ year = yr, month = mth, day = dy }) or ""
    local short_month = datetime.shortMonthTranslation[month_abbr] or ""
    hl_date = yr and mth and dy and short_month and string.format("%s %s '%02d", dy, short_month, tonumber(yr) % 100) or "N/A"

    local timesplit = date_and_time[2] and util.splitToArray(date_and_time[2], ":") or {}
    local hl_time = timesplit[1] and timesplit[2] and (timesplit[1] .. ":" .. timesplit[2]) or "N/A"

    local sub_table = {
        ["%%HM"] = hl_time,
        ["%%DT"] = hl_date,
        ["%%PG"] = hl_pageno,
        ["%%C"] = hl_chapter,
        ["%%A"] = bk_author,
        ["%%T"] = bk_title,
    }
    for pattern, replacement in pairs(sub_table) do
        if replacement then
            text = string.gsub(text, pattern, replacement)
        end
    end
    return text
end

---@param opts table|nil optional: `force_full_width`; `height_adjust` (default true, false = высота ровно max_height).
function BannerText.buildTextField(B_SETT, HL_SETT, text, font_face, max_height, max_wid, ignoreLineBreaks, isHighlight, text_color, bgcolor_override, opts)
    opts = opts or {}
    local Bb = require("ffi/blitbuffer")
    if font_face == nil then
        local Font = require("ui/font")
        font_face = Font:getFace("cfont", 20)
    end
    local wgt_grp = VerticalGroup:new{ align = "left" }
    text = text:gsub("\\n", "\n")
    local default_fg = Bb.COLOR_BLACK
    local default_bg = Bb.COLOR_WHITE
    if type(B_SETT) == "table" and B_SETT.background == 1 then
        default_fg = Bb.COLOR_WHITE
        default_bg = Bb.COLOR_BLACK
    end
    -- BlitBuffer colors are userdata with __eq: never use `c == nil` (invokes __eq(self, nil) → crash).
    local fg = default_fg
    if not rawequal(text_color, nil) and not (type(text_color) == "boolean" and text_color == false) then
        fg = text_color
    end
    local bg = default_bg
    if not rawequal(bgcolor_override, nil) and not (type(bgcolor_override) == "boolean" and bgcolor_override == false) then
        bg = bgcolor_override
    end
    if rawequal(fg, nil) then
        fg = Bb.COLOR_BLACK
    end
    if rawequal(bg, nil) then
        bg = Bb.COLOR_WHITE
    end
    --- false — фиксированная высота max_height (например цитата на всю ячейку); по умолчанию true.
    local tb_height_adjust = opts.height_adjust
    if tb_height_adjust == nil then
        tb_height_adjust = true
    end

    local segments = ignoreLineBreaks and { text } or util.splitToArray(text, "\n")
    for _, item in ipairs(segments) do
        local wgt
        if opts.force_full_width then
            wgt = TextBoxWidget:new{
                text = item,
                face = font_face,
                width = max_wid,
                alignment = "left",
                height = max_height,
                height_adjust = tb_height_adjust,
                height_overflow_show_ellipsis = true,
                justified = isHighlight and type(HL_SETT) == "table" and HL_SETT.justify,
                fgcolor = fg,
                bgcolor = bg,
            }
        else
            wgt = TextWidget:new{
                padding = 0,
                text = item,
                face = font_face,
                alignment = "left",
                fgcolor = fg,
                bgcolor = bg,
            }
            if wgt:getSize().w > max_wid then
                wgt:free()
                wgt = TextBoxWidget:new{
                    text = item,
                    face = font_face,
                    width = max_wid,
                    alignment = "left",
                    height = max_height,
                    height_adjust = tb_height_adjust,
                    height_overflow_show_ellipsis = true,
                    justified = isHighlight and type(HL_SETT) == "table" and HL_SETT.justify,
                    fgcolor = fg,
                    bgcolor = bg,
                }
            end
        end
        table.insert(wgt_grp, wgt)
    end
    return wgt_grp
end

return BannerText

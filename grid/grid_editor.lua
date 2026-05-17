--[[ Placements / widget editing via nested TouchMenu tables (6×3 grid, horizontal span). ]]
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")

local Config = require("config")
local CellMenuContext = require("grid.cell_menu_context")
local GridModel = require("grid.grid_model")
local Registry = require("banner.widgets.registry")
local RowMenuHint = require("grid.row_menu_hint")
local Settings = require("settings")

local _ = require("l10n").gettext

local GridEditor = {}

local function pop_menu_one_level(touchmenu)
    if touchmenu and touchmenu.backToUpperMenu then
        touchmenu:backToUpperMenu(true)
    end
end

local function default_fn(type_id)
    Registry.ensure_registered()
    return Registry.default_col_span(type_id)
end

local function copy_params(p)
    local o = {}
    if type(p) == "table" then
        for k, v in pairs(p) do
            o[k] = v
        end
    end
    return o
end

local function region_free(placements, row, col, span)
    local occ = GridModel.occupancy_flags(placements, default_fn)
    for dc = 0, span - 1 do
        local c = col + dc
        if c > GridModel.GRID_COLS or occ[row][c] then
            return false
        end
    end
    return true
end

---@return integer|nil idx, boolean is_anchor
local function cover_info(placements, row, col)
    for i, p in ipairs(placements) do
        local span = GridModel.resolveColSpan(p.type, p.params, p.row, p.col, default_fn)
        if p.row == row and col >= p.col and col < p.col + span then
            return i, p.col == col
        end
    end
    return nil, false
end

local function try_add_widget(row, col, proto, touchmenu, levels_up)
    local list = Settings:getGridPlacements()
    local span = GridModel.resolveColSpan(proto.type, proto.params, row, col, default_fn)
    if not region_free(list, row, col, span) then
        UIManager:show(InfoMessage:new{
            text = _("Not enough space for this widget here."),
            timeout = 3,
        })
        return
    end
    table.insert(list, {
        type = proto.type,
        params = proto.params,
        row = row,
        col = col,
    })
    Settings:saveGridPlacements(list)
    local n = tonumber(levels_up) or 1
    for _ = 1, n do
        pop_menu_one_level(touchmenu)
    end
end

local function try_set_span(idx, span_val, touchmenu)
    local list = Settings:getGridPlacements()
    local w = list[idx]
    if not w then
        return
    end
    local copy = {}
    for i, p in ipairs(list) do
        if i ~= idx then
            table.insert(copy, p)
        end
    end
    local np = {
        type = w.type,
        row = w.row,
        col = w.col,
        params = copy_params(w.params),
    }
    if span_val <= 1 then
        np.params.col_span = nil
    else
        np.params.col_span = span_val
    end
    table.insert(copy, np)
    local norm = GridModel.normalizePlacements(copy, default_fn)
    local ok = false
    for _, q in ipairs(norm) do
        if q.row == w.row and q.col == w.col and q.type == w.type then
            ok = true
            break
        end
    end
    if not ok then
        UIManager:show(InfoMessage:new{
            text = _("That width does not fit here."),
            timeout = 3,
        })
        return
    end
    Settings:saveGridPlacements(norm)
    pop_menu_one_level(touchmenu)
end

local function default_widget(widget_type)
    Registry.ensure_registered()
    if widget_type == "template" then
        return { type = "template", params = Config.default_template_widget_params() }
    elseif widget_type == "highlight" then
        return { type = "highlight", params = {} }
    elseif widget_type == "clock" then
        return {
            type = "clock",
            params = Config.default_digital_clock_params(),
        }
    elseif widget_type == "datetime" then
        return { type = "datetime", params = {} }
    elseif widget_type == "battery" then
        return { type = "battery", params = {} }
    elseif widget_type == "reading_now" then
        return {
            type = "reading_now",
            params = Registry.normalize_widget_params("reading_now", {}),
        }
    elseif widget_type == "calendar" then
        return {
            type = "calendar",
            params = Registry.normalize_widget_params("calendar", {}),
        }
    elseif widget_type == "activity" then
        return {
            type = "activity",
            params = Registry.normalize_widget_params("activity", {}),
        }
    end
    return { type = widget_type, params = {} }
end

local function proto_with_span(widget_type, span_val)
    local p = default_widget(widget_type)
    if span_val <= 1 then
        p.params.col_span = nil
    else
        p.params.col_span = span_val
    end
    return p
end

--- Submenu when opening a single cell from the row menu: no extra "Edit…" wrapper.
local function submenu_for_cell(row, col)
    local placements = Settings:getGridPlacements()
    local idx, is_anchor = cover_info(placements, row, col)
    if not idx then
        return GridEditor.addWidgetMenu(row, col)
    end
    local p = placements[idx]
    if is_anchor then
        return GridEditor.widgetMenu(row, col)
    end
    return GridEditor.widgetMenu(p.row, p.col)
end

function GridEditor.addWidgetMenu(row, col)
    local max_col_span = GridModel.maxSpanForCol(col)
    local function span_label(s)
        if s == 1 then
            return _("1 column")
        elseif s == 2 then
            return _("2 columns")
        end
        return _("3 columns")
    end
    local function item_with_width(label, wtype)
        if max_col_span <= 1 then
            return {
                text = label,
                keep_menu_open = true,
                callback = function(touchmenu)
                    try_add_widget(row, col, proto_with_span(wtype, 1), touchmenu, 1)
                end,
            }
        end
        return {
            text = label,
            keep_menu_open = true,
            sub_item_table_func = function()
                local sub = {}
                for s = 1, max_col_span do
                    local span = s
                    table.insert(sub, {
                        text = span_label(s),
                        keep_menu_open = true,
                        callback = function(touchmenu)
                            try_add_widget(row, col, proto_with_span(wtype, span), touchmenu, 2)
                        end,
                    })
                end
                return sub
            end,
        }
    end

    return {
        item_with_width(_("Date & time"), "datetime"),
        item_with_width(_("Clock"), "clock"),
        item_with_width(_("Random highlight"), "highlight"),
        item_with_width(_("Battery status"), "battery"),
        item_with_width(_("Current book status"), "reading_now"),
        item_with_width(_("Calendar"), "calendar"),
        item_with_width(_("Activity"), "activity"),
        item_with_width(_("Text template"), "template"),
    }
end

local function anchor_index(placements, row, col)
    for i, p in ipairs(placements) do
        if p.row == row and p.col == col then
            return i
        end
    end
    return nil
end

function GridEditor.widgetMenu(row, col)
    local placements = Settings:getGridPlacements()
    local idx = anchor_index(placements, row, col)
    local widget = idx and placements[idx]
    if not widget then
        return {}
    end
    local items = {}
    Registry.ensure_registered()

    local function effective_span()
        local pl = Settings:getGridPlacements()
        local i = anchor_index(pl, row, col)
        local w = i and pl[i]
        if not w then return 1 end
        return GridModel.resolveColSpan(w.type, w.params, w.row, w.col, default_fn)
    end

    table.insert(items, {
        text = _("Widget width: 1 column"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            return effective_span() == 1
        end,
        callback = function(touchmenu)
            local i = anchor_index(Settings:getGridPlacements(), row, col)
            if i then try_set_span(i, 1, touchmenu) end
        end,
    })
    table.insert(items, {
        text = _("Widget width: 2 columns"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            return effective_span() == 2
        end,
        callback = function(touchmenu)
            local i = anchor_index(Settings:getGridPlacements(), row, col)
            if i then try_set_span(i, 2, touchmenu) end
        end,
    })
    table.insert(items, {
        text = _("Widget width: 3 columns"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            return effective_span() == 3
        end,
        callback = function(touchmenu)
            local i = anchor_index(Settings:getGridPlacements(), row, col)
            if i then try_set_span(i, 3, touchmenu) end
        end,
    })

    local ctx = CellMenuContext.new(idx, row, col, pop_menu_one_level)
    for _, it in ipairs(Registry.cell_menu_items(widget.type, ctx)) do
        table.insert(items, it)
    end

    table.insert(items, {
        text = _("Remove widget"),
        keep_menu_open = true,
        callback = function(touchmenu)
            local pl = Settings:getGridPlacements()
            local i = anchor_index(pl, row, col)
            if i then
                table.remove(pl, i)
                Settings:saveGridPlacements(pl)
            end
            pop_menu_one_level(touchmenu)
        end,
    })

    return items
end

local function slot_label(row, col)
    local placements = Settings:getGridPlacements()
    local idx, is_anchor = cover_info(placements, row, col)
    if not idx then
        return string.format(_("Row %d, column %d — empty"), row, col)
    end
    local p = placements[idx]
    local span = GridModel.resolveColSpan(p.type, p.params, p.row, p.col, default_fn)
    if is_anchor then
        if span > 1 then
            return string.format(_("Row %d, column %d — %s (%d cols)"), row, col, p.type, span)
        end
        return string.format(_("Row %d, column %d — %s"), row, col, p.type)
    end
    return string.format(_("Row %d, column %d — (wider widget @ %d,%d)"), row, col, p.row, p.col)
end

function GridEditor.rowMenu(row)
    local items = {}
    for col = 1, GridModel.GRID_COLS do
        table.insert(items, {
            text = slot_label(row, col),
            sub_item_table_func = function()
                return submenu_for_cell(row, col)
            end,
        })
    end
    items.needs_refresh = true
    items.refresh_func = function()
        return GridEditor.rowMenu(row)
    end
    return items
end

function GridEditor.gridZonesMenu()
    local items = {}
    local placements = Settings:getGridPlacements()
    for row = 1, GridModel.GRID_ROWS do
        local hint = RowMenuHint.row_hint(placements, row, default_fn)
        table.insert(items, {
            text = string.format(_("Row %d (%s)"), row, hint),
            sub_item_table_func = function()
                return GridEditor.rowMenu(row)
            end,
        })
    end
    items.needs_refresh = true
    items.refresh_func = function()
        return GridEditor.gridZonesMenu()
    end
    return items
end

return GridEditor

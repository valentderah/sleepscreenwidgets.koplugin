local Registry = require("banner.widgets.registry")

local _ = require("l10n").gettext

local M = {}

local function merged_params(raw_params)
    return Registry.normalize_widget_params("calendar", raw_params)
end

function M.items(ctx)
    local items = {}

    table.insert(items, {
        text = _("Calendar: day view"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            local p = ctx.read_placement()
            local m = merged_params(p and p.params)
            return m.calendar_layout ~= "month"
        end,
        callback = function()
            ctx.mutate(function(pp)
                pp.params = pp.params or {}
                pp.params.calendar_layout = "day"
            end)
        end,
    })

    table.insert(items, {
        text = _("Calendar: month grid"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            local p = ctx.read_placement()
            local m = merged_params(p and p.params)
            return m.calendar_layout == "month"
        end,
        callback = function()
            ctx.mutate(function(pp)
                pp.params = pp.params or {}
                pp.params.calendar_layout = "month"
            end)
        end,
    })

    table.insert(items, {
        text = _("Calendar: week starts Monday"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            local p = ctx.read_placement()
            local m = merged_params(p and p.params)
            return m.week_start ~= "sun"
        end,
        callback = function()
            ctx.mutate(function(pp)
                pp.params = pp.params or {}
                pp.params.week_start = "mon"
            end)
        end,
    })

    table.insert(items, {
        text = _("Calendar: week starts Sunday"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            local p = ctx.read_placement()
            local m = merged_params(p and p.params)
            return m.week_start == "sun"
        end,
        callback = function()
            ctx.mutate(function(pp)
                pp.params = pp.params or {}
                pp.params.week_start = "sun"
            end)
        end,
    })

    table.insert(items, {
        text = _("Card theme"),
        keep_menu_open = true,
        sub_item_table_func = function()
            local function set_card_theme(v, touchmenu)
                ctx.mutate(function(pp)
                    pp.params = pp.params or {}
                    if v == nil then
                        pp.params.card_theme = nil
                    else
                        pp.params.card_theme = v
                    end
                end)
                ctx.pop_menu(touchmenu)
            end
            local function is_checked(v)
                local w = ctx.read_placement()
                local cur = w and w.params and w.params.card_theme or nil
                return cur == v
            end
            return {
                {
                    text = _("Inherit"),
                    radio = true,
                    checked_func = function()
                        return is_checked(nil)
                    end,
                    callback = function(touchmenu)
                        set_card_theme(nil, touchmenu)
                    end,
                },
                {
                    text = _("Light"),
                    radio = true,
                    checked_func = function()
                        return is_checked("light")
                    end,
                    callback = function(touchmenu)
                        set_card_theme("light", touchmenu)
                    end,
                },
                {
                    text = _("Dark"),
                    radio = true,
                    checked_func = function()
                        return is_checked("dark")
                    end,
                    callback = function(touchmenu)
                        set_card_theme("dark", touchmenu)
                    end,
                },
            }
        end,
    })

    return items
end

return M

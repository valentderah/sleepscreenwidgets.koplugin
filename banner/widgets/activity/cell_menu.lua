local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")

local _ = require("l10n").gettext

local M = {}

function M.items(ctx)
    local items = {}

    local function cur_variant()
        local w = ctx.read_placement()
        local v = w and w.params and w.params.variant
        if v == "week" then
            return "week"
        end
        return "day"
    end

    table.insert(items, {
        text = _("Activity: daily rings"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            return cur_variant() == "day"
        end,
        callback = function()
            ctx.mutate(function(pp)
                pp.params = pp.params or {}
                pp.params.variant = "day"
            end)
        end,
    })

    table.insert(items, {
        text = _("Activity: week strip"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            return cur_variant() == "week"
        end,
        callback = function()
            ctx.mutate(function(pp)
                pp.params = pp.params or {}
                pp.params.variant = "week"
            end)
        end,
    })

    table.insert(items, {
        text = _("Week starts on"),
        keep_menu_open = true,
        sub_item_table_func = function()
            local function cur_ws()
                local w = ctx.read_placement()
                local ws = w and w.params and w.params.week_start
                if ws == "sun" then
                    return "sun"
                end
                return "mon"
            end
            local function set_ws(v, touchmenu)
                ctx.mutate(function(pp)
                    pp.params = pp.params or {}
                    pp.params.week_start = v
                end)
                ctx.pop_menu(touchmenu)
            end
            return {
                {
                    text = _("Monday"),
                    radio = true,
                    checked_func = function()
                        return cur_ws() == "mon"
                    end,
                    callback = function(touchmenu)
                        set_ws("mon", touchmenu)
                    end,
                },
                {
                    text = _("Sunday"),
                    radio = true,
                    checked_func = function()
                        return cur_ws() == "sun"
                    end,
                    callback = function(touchmenu)
                        set_ws("sun", touchmenu)
                    end,
                },
            }
        end,
    })

    table.insert(items, {
        text = _("Week title…"),
        keep_menu_open = true,
        callback = function(touchmenu)
            local p = ctx.read_placement()
            local dlg
            dlg = InputDialog:new{
                title = _("Week widget title (empty = default)"),
                input = (p and p.params and type(p.params.title) == "string") and p.params.title or "",
                buttons = {{
                    {
                        text = _("Cancel"),
                        callback = function()
                            UIManager:close(dlg)
                        end,
                    },
                    {
                        text = _("Save"),
                        is_enter_default = true,
                        callback = function()
                            local text = dlg:getInputText()
                            ctx.mutate(function(pp)
                                pp.params = pp.params or {}
                                pp.params.title = type(text) == "string" and text or ""
                            end)
                            UIManager:close(dlg)
                            ctx.pop_menu(touchmenu)
                        end,
                    },
                }},
            }
            UIManager:show(dlg)
            dlg:onShowKeyboard()
        end,
    })

    table.insert(items, {
        text = _("Daily goal (statistics minutes)…"),
        keep_menu_open = true,
        callback = function(touchmenu)
            local p = ctx.read_placement()
            local dlg
            dlg = InputDialog:new{
                title = _("Daily goal (minutes, 0 = no ring cap)"),
                input = tostring((p and p.params and tonumber(p.params.daily_goal_minutes)) or 0),
                input_type = "number",
                buttons = {{
                    {
                        text = _("Cancel"),
                        callback = function()
                            UIManager:close(dlg)
                        end,
                    },
                    {
                        text = _("Save"),
                        is_enter_default = true,
                        callback = function()
                            local n = tonumber(dlg:getInputText())
                            if n ~= nil and n >= 0 then
                                ctx.mutate(function(pp)
                                    pp.params = pp.params or {}
                                    pp.params.daily_goal_minutes = math.floor(n)
                                end)
                            end
                            UIManager:close(dlg)
                            ctx.pop_menu(touchmenu)
                        end,
                    },
                }},
            }
            UIManager:show(dlg)
            dlg:onShowKeyboard()
        end,
    })

    table.insert(items, {
        text = _("Daily goal (pages)…"),
        keep_menu_open = true,
        callback = function(touchmenu)
            local p = ctx.read_placement()
            local dlg
            dlg = InputDialog:new{
                title = _("Daily goal (pages, 0 = disabled)"),
                input = tostring((p and p.params and tonumber(p.params.daily_goal_pages)) or 0),
                input_type = "number",
                buttons = {{
                    {
                        text = _("Cancel"),
                        callback = function()
                            UIManager:close(dlg)
                        end,
                    },
                    {
                        text = _("Save"),
                        is_enter_default = true,
                        callback = function()
                            local n = tonumber(dlg:getInputText())
                            if n ~= nil and n >= 0 then
                                ctx.mutate(function(pp)
                                    pp.params = pp.params or {}
                                    pp.params.daily_goal_pages = math.floor(n)
                                end)
                            end
                            UIManager:close(dlg)
                            ctx.pop_menu(touchmenu)
                        end,
                    },
                }},
            }
            UIManager:show(dlg)
            dlg:onShowKeyboard()
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

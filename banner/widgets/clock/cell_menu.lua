local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")

local _ = require("l10n").gettext

local M = {}

local function params_are_analog(params)
    if type(params) ~= "table" then
        return false
    end
    local v = params.variant
    if type(v) ~= "string" then
        return false
    end
    return string.lower(v) == "analog"
end

function M.items(ctx)
    local items = {}

    table.insert(items, {
        text = _("Clock face: digital (text)"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            local p = ctx.read_placement()
            return p ~= nil and not params_are_analog(p.params)
        end,
        callback = function()
            ctx.mutate(function(pp)
                pp.params = pp.params or {}
                pp.params.variant = "digital"
                pp.params.diameter_pct = nil
            end)
        end,
    })

    table.insert(items, {
        text = _("Clock face: analog"),
        radio = true,
        keep_menu_open = true,
        checked_func = function()
            local p = ctx.read_placement()
            return p ~= nil and params_are_analog(p.params)
        end,
        callback = function()
            ctx.mutate(function(pp)
                pp.params = pp.params or {}
                pp.params.variant = "analog"
                if tonumber(pp.params.diameter_pct) == nil then
                    pp.params.diameter_pct = 100
                end
            end)
        end,
    })

    table.insert(items, {
        text = _("Edit time format…"),
        keep_menu_open = true,
        callback = function(touchmenu)
            local p = ctx.read_placement()
            local dlg
            dlg = InputDialog:new{
                title = _("strftime format"),
                input = (p and p.params and p.params.format) or "%H:%M",
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
                                pp.params.format = text
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
        text = _("Analog dial diameter % (50–100)…"),
        keep_menu_open = true,
        callback = function(touchmenu)
            local p = ctx.read_placement()
            local dlg
            dlg = InputDialog:new{
                title = _("Dial diameter"),
                input = tostring((p and p.params and p.params.diameter_pct) or 100),
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
                            if n then
                                n = math.max(50, math.min(100, math.floor(n)))
                                ctx.mutate(function(pp)
                                    pp.params = pp.params or {}
                                    pp.params.diameter_pct = n
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

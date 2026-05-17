local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")

local _ = require("l10n").gettext

local M = {}

function M.items(ctx)
    local items = {}

    table.insert(items, {
        text = _("Edit template pattern…"),
        keep_menu_open = true,
        callback = function(touchmenu)
            local dlg
            local p = ctx.read_placement()
            dlg = InputDialog:new{
                title = _("Template"),
                input = (p and p.params and p.params.pattern) or "",
                input_hint = _("%T %c …"),
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
                                pp.params.pattern = text
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

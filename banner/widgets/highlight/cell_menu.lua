local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")

local _ = require("l10n").gettext

local M = {}

function M.items(ctx)
    local items = {}

    table.insert(items, {
        text = _("Highlight uses document annotations (see KOReader docs)."),
        keep_menu_open = true,
        callback = function()
            UIManager:show(InfoMessage:new{
                text = _("Footer line: use %%DT, %%HM, %%PG, %%C, %%A, %%T in banner highlight settings (doubled %%)."),
                timeout = 3,
            })
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

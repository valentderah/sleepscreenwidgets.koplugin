--[[ TouchMenu: widget instance params from Registry.param_fields + params.menu.expose. ]]
local Registry = require("banner.widgets.registry")
local Settings = require("settings")
local ExposeKeys = require("menu.expose_keys")

local InstanceParamMenu = require("menu.instance_param_menu")

local _ = require("l10n").gettext

local MenuWidgetInstances = {}

function MenuWidgetInstances.build()
    require("l10n").load()
    Registry.ensure_registered()
    local items = {}
    local placements = Settings:getGridPlacements()
    for i, p in ipairs(placements) do
        local merged = Registry.normalize_widget_params(p.type, p.params)
        local menu_tbl = merged.menu or {}
        local exposes = menu_tbl.expose or {}
        local keys = ExposeKeys.expose_ordered_keys(exposes, menu_tbl.order or {})
        if #keys > 0 then
            table.insert(items, {
                text = (p.type or "?") .. " · #" .. tostring(i),
                sub_item_table_func = function()
                    return InstanceParamMenu.submenu_for_placement(i)
                end,
            })
        end
    end
    if #items == 0 then
        table.insert(items, {
            text = _("No exposed widget parameters"),
            enabled = false,
        })
    end
    return items
end

return MenuWidgetInstances

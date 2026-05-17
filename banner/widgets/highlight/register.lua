local M = {}

local DEFAULT_WIDGET_PARAMS = {
    card_theme = "light",
    menu = {
        expose = { card_theme = true },
        order = { "card_theme" },
    },
}

local PARAM_FIELDS = {
    card_theme = {
        kind = "enum",
        title = "Card theme",
        options = {
            { value = nil, label = "Inherit" },
            { value = "light", label = "Light" },
            { value = "dark", label = "Dark" },
        },
    },
}

M.WIDGET_REGISTER_STATIC = {
    default_params = DEFAULT_WIDGET_PARAMS,
    param_fields = PARAM_FIELDS,
}

function M.attach(Registry)
    local Build = require("banner.widgets.highlight.build")
    local CellMenu = require("banner.widgets.highlight.cell_menu")
    Registry.register("highlight", function(params, ctx)
        return Build.build(params, ctx)
    end, {
        default_params = M.WIDGET_REGISTER_STATIC.default_params,
        param_fields = M.WIDGET_REGISTER_STATIC.param_fields,
        cell_menu = function(ctx)
            return CellMenu.items(ctx)
        end,
    })
end

return M

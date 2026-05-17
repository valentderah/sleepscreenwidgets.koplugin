local M = {}

local DEFAULT_WIDGET_PARAMS = {
    show_cover = false,
    menu = {
        expose = { show_cover = true, card_theme = true },
        order = { "show_cover", "card_theme" },
    },
}

local PARAM_FIELDS = {
    show_cover = {
        kind = "boolean",
        title = "Show book cover thumbnail",
    },
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

function M.clone_default_params(extra)
    local out = { show_cover = DEFAULT_WIDGET_PARAMS.show_cover }
    out.menu = { expose = {}, order = {} }
    for k, v in pairs(DEFAULT_WIDGET_PARAMS.menu.expose) do
        out.menu.expose[k] = v
    end
    for i, v in ipairs(DEFAULT_WIDGET_PARAMS.menu.order) do
        out.menu.order[i] = v
    end
    if type(extra) == "table" then
        for k, v in pairs(extra) do
            out[k] = v
        end
    end
    return out
end

function M.attach(Registry)
    local Build = require("banner.widgets.reading_now.build")
    Registry.register("reading_now", function(params, ctx)
        return Build.build(params, ctx)
    end, {
        default_params = M.WIDGET_REGISTER_STATIC.default_params,
        param_fields = M.WIDGET_REGISTER_STATIC.param_fields,
    })
end

return M

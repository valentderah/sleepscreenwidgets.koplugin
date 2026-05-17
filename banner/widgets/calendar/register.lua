local M = {}

local DEFAULT_WIDGET_PARAMS = {
    card_theme = "light",
    calendar_layout = "month",
    week_start = "mon",
    menu = {
        expose = { card_theme = true, calendar_layout = true, week_start = true },
        order = { "calendar_layout", "week_start", "card_theme" },
    },
}

local PARAM_FIELDS = {
    calendar_layout = {
        kind = "enum",
        title = "Calendar layout",
        options = {
            { value = "day", label = "Day" },
            { value = "month", label = "Month grid" },
        },
    },
    week_start = {
        kind = "enum",
        title = "Week starts on",
        options = {
            { value = "mon", label = "Monday" },
            { value = "sun", label = "Sunday" },
        },
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

function M.clone_default_params()
    local b = DEFAULT_WIDGET_PARAMS
    local out = { card_theme = b.card_theme, calendar_layout = b.calendar_layout, week_start = b.week_start }
    out.menu = { expose = {}, order = {} }
    for k, v in pairs(b.menu.expose) do
        out.menu.expose[k] = v
    end
    for i, v in ipairs(b.menu.order) do
        out.menu.order[i] = v
    end
    return out
end

function M.attach(Registry)
    local Build = require("banner.widgets.calendar.build")
    local CellMenu = require("banner.widgets.calendar.cell_menu")
    Registry.register("calendar", function(params, ctx)
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

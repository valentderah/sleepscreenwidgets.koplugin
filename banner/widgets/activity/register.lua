local M = {}

local DEFAULT_WIDGET_PARAMS = {
    variant = "day",
    week_start = "mon",
    title = "",
    daily_goal_minutes = 60,
    daily_goal_pages = 30,
    card_theme = "light",
    menu = {
        expose = {
            variant = true,
            week_start = true,
            daily_goal_minutes = true,
            daily_goal_pages = true,
            card_theme = true,
        },
        order = {
            "variant",
            "week_start",
            "daily_goal_minutes",
            "daily_goal_pages",
            "card_theme",
        },
    },
}

local PARAM_FIELDS = {
    variant = {
        kind = "enum",
        title = "Activity layout",
        options = {
            { value = "day", label = "Daily rings" },
            { value = "week", label = "Week strip" },
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
    daily_goal_minutes = {
        kind = "number",
        title = "Daily goal minutes",
        min = 0,
        help = "0 = no cap ring",
    },
    daily_goal_pages = {
        kind = "number",
        title = "Daily goal pages",
        min = 0,
        help = "0 = disabled",
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

M.DEFAULT_WIDGET_PARAMS = DEFAULT_WIDGET_PARAMS

function M.clone_default_params()
    local b = DEFAULT_WIDGET_PARAMS
    local out = {
        variant = b.variant,
        week_start = b.week_start,
        title = b.title,
        daily_goal_minutes = b.daily_goal_minutes,
        daily_goal_pages = b.daily_goal_pages,
        card_theme = b.card_theme,
    }
    out.menu = { expose = {}, order = {} }
    for k, v in pairs(b.menu.expose) do
        out.menu.expose[k] = v
    end
    for i, v in ipairs(b.menu.order) do
        out.menu.order[i] = v
    end
    return out
end

M.WIDGET_REGISTER_STATIC = {
    default_params = DEFAULT_WIDGET_PARAMS,
    param_fields = PARAM_FIELDS,
}

function M.attach(Registry)
    local Build = require("banner.widgets.activity.build")
    local CellMenu = require("banner.widgets.activity.cell_menu")
    Registry.register("activity", function(params, ctx)
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

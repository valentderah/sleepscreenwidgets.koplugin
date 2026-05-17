local M = {}

function M.build(params, ctx)
    params = params or {}
    local v = params.variant == "week" and "week" or "day"
    if v == "week" then
        return require("banner.widgets.activity.week_build").build(params, ctx)
    end
    return require("banner.widgets.activity.day_build").build(params, ctx)
end

return M

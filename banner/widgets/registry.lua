local logger = require("logger")

local Registry = { _types = {}, _meta = {} }

--[[ Instance submenu (menu_widget_instances / instance_param_menu):
    Any parameter editable there needs both Registry.param_fields[type] and
    default_params.menu.expose (+ optional menu.order). Types without expose
    rely on grid editor / cell_menu only — unchanged UX (spec §C.3). ]]

function Registry.register(type_id, builder, meta)
    Registry._types[type_id] = builder
    meta = meta or {}
    local span = tonumber(meta.default_col_span)
    if span ~= 2 and span ~= 3 then
        span = 1
    end
    Registry._meta[type_id] = {
        default_col_span = span,
        cell_menu = meta.cell_menu,
        default_params = type(meta.default_params) == "table" and meta.default_params or {},
        param_fields = type(meta.param_fields) == "table" and meta.param_fields or {},
    }
end

function Registry.default_col_span(type_id)
    local m = Registry._meta[type_id]
    return (m and m.default_col_span) or 1
end

function Registry.default_params(type_id)
    local m = Registry._meta[type_id]
    return (m and m.default_params) or {}
end

function Registry.param_fields(type_id)
    local m = Registry._meta[type_id]
    return (m and m.param_fields) or {}
end

--- Merge saved params over registry defaults (`menu` subtable merged one level).
function Registry.normalize_widget_params(type_id, params)
    local base = Registry.default_params(type_id)
    local out = {}
    for k, v in pairs(base) do
        out[k] = v
    end
    if type(params) ~= "table" then
        return out
    end
    for k, v in pairs(params) do
        if k == "menu" and type(v) == "table" and type(out.menu) == "table" then
            local om = {}
            for mk, mv in pairs(out.menu) do
                om[mk] = mv
            end
            for mk, mv in pairs(v) do
                om[mk] = mv
            end
            out.menu = om
        else
            out[k] = v
        end
    end
    return out
end

function Registry.build(block, ctx)
    local id = block.type
    local fn = Registry._types[id]
    if not fn then
        logger.warn("sleepscreenwidgets", "unknown widget type: " .. tostring(id))
        return nil
    end
    local params = Registry.normalize_widget_params(id, block.params)
    return fn(params, ctx)
end

--- @param type_id string
--- @param ctx table контекст ячейки (см. grid.cell_menu_context)
--- @return table пункты TouchMenu для типа; пустая таблица без провайдера или при ошибке
function Registry.cell_menu_items(type_id, ctx)
    local m = Registry._meta[type_id]
    if not m or type(m.cell_menu) ~= "function" then
        return {}
    end
    local ok, items = pcall(m.cell_menu, ctx)
    if not ok or type(items) ~= "table" then
        if not ok then
            logger.warn("sleepscreenwidgets", "cell_menu failed for " .. tostring(type_id) .. ": " .. tostring(items))
        end
        return {}
    end
    return items
end

--- For unit tests only: clear registration state (standalone `lua` cannot load all builders).
function Registry.__test_reset()
    Registry._registered = false
    Registry._types = {}
    Registry._meta = {}
end

function Registry.ensure_registered()
    if Registry._registered then
        return
    end
    Registry._registered = true
    Registry._meta = {}
    local order = {
        "template",
        "highlight",
        "clock",
        "datetime",
        "battery",
        "reading_now",
        "activity",
        "calendar",
    }
    for _, id in ipairs(order) do
        -- KOReader package.path has no ?/init.lua; load folder entry by explicit ".init" suffix.
        local pack = assert(require("banner.widgets." .. id .. ".init"), "widget pack missing: " .. id)
        assert(type(pack.attach) == "function", "widget pack must export attach(): " .. id)
        pack.attach(Registry)
    end
end

return Registry

--[[ TouchMenu items for params listed in params.menu.expose; field types from Registry.param_fields. ]]
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")

local Registry = require("banner.widgets.registry")
local Settings = require("settings")
local ExposeKeys = require("menu.expose_keys")

local _ = require("l10n").gettext

local M = {}

local function edit_number_dialog(title, read_fn, save_fn)
    local dlg
    dlg = InputDialog:new{
        title = title,
        input = tostring(read_fn()),
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
                        save_fn(math.floor(n))
                    end
                    UIManager:close(dlg)
                end,
            },
        }},
    }
    UIManager:show(dlg)
    dlg:onShowKeyboard()
end

function M.submenu_for_placement(idx)
    Registry.ensure_registered()
    local pl = Settings:getGridPlacements()
    local placement = pl[idx]
    if not placement or type(placement.type) ~= "string" then
        return {}
    end
    local wtype = placement.type
    local merged = Registry.normalize_widget_params(wtype, placement.params)
    local menu_cfg = merged.menu or {}
    local exposes = menu_cfg.expose or {}
    local keys = ExposeKeys.expose_ordered_keys(exposes, menu_cfg.order or {})
    if #keys == 0 then
        return {}
    end

    local fields = Registry.param_fields(wtype)
    local items = {}

    for _i, key in ipairs(keys) do
        local spec = fields[key]
        if type(spec) == "table" and type(spec.kind) == "string" then
            if spec.kind == "number" then
                local min_v = tonumber(spec.min) or 0
                local title_base = type(spec.title) == "string" and _(spec.title) or tostring(spec.title)
                local dlg_title = title_base
                if type(spec.help) == "string" and spec.help ~= "" then
                    dlg_title = title_base .. " — " .. _(spec.help)
                end
                table.insert(items, {
                    text = title_base .. (" (#" .. tostring(idx) .. ")"),
                    keep_menu_open = true,
                    callback = function()
                        edit_number_dialog(dlg_title, function()
                            local p2 = Settings:getGridPlacements()
                            local pv = p2[idx] and p2[idx].params or {}
                            return tonumber(pv[key]) or min_v
                        end, function(val)
                            val = math.max(min_v, val)
                            local p2 = Settings:getGridPlacements()
                            if p2[idx] then
                                p2[idx].params = p2[idx].params or {}
                                p2[idx].params[key] = val
                                Settings:saveGridPlacements(p2)
                            end
                        end)
                    end,
                })
            elseif spec.kind == "boolean" then
                local title_base = type(spec.title) == "string" and _(spec.title) or tostring(spec.title)
                table.insert(items, {
                    text = title_base .. (" (#" .. tostring(idx) .. ")"),
                    keep_menu_open = true,
                    checked_func = function()
                        local p2 = Settings:getGridPlacements()
                        local pv = p2[idx] and p2[idx].params or {}
                        return pv[key] == true
                    end,
                    callback = function()
                        local p2 = Settings:getGridPlacements()
                        if p2[idx] then
                            p2[idx].params = p2[idx].params or {}
                            p2[idx].params[key] = not (p2[idx].params[key] == true)
                            Settings:saveGridPlacements(p2)
                        end
                    end,
                })
            elseif spec.kind == "enum" and type(spec.options) == "table" then
                local title_base = type(spec.title) == "string" and _(spec.title) or tostring(spec.title)
                table.insert(items, {
                    text = title_base .. (" (#" .. tostring(idx) .. ")"),
                    sub_item_table_func = function()
                        local radio_items = {}
                        for _j, opt in ipairs(spec.options) do
                            local val = opt.value
                            local label = opt.label
                            if type(label) == "string" then
                                label = _(label)
                            else
                                label = tostring(label)
                            end
                            table.insert(radio_items, {
                                text = label,
                                radio = true,
                                checked_func = function()
                                    local p2 = Settings:getGridPlacements()
                                    local pv = p2[idx] and p2[idx].params or {}
                                    local cur = pv[key]
                                    if cur == nil then
                                        cur = merged[key]
                                    end
                                    return cur == val
                                end,
                                callback = function()
                                    local p2 = Settings:getGridPlacements()
                                    if not p2[idx] then
                                        return
                                    end
                                    p2[idx].params = p2[idx].params or {}
                                    p2[idx].params[key] = val
                                    Settings:saveGridPlacements(p2)
                                end,
                            })
                        end
                        return radio_items
                    end,
                })
            end
        end
    end

    return items
end

return M

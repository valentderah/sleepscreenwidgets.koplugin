local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")

local Config = require("config")
local Settings = require("settings")
local MenuWidgetInstances = require("menu.menu_widget_instances")
local BannerDp = require("grid.banner_dp")
local BannerIO = require("menu.banner_settings_io")

local GridEditor = require("grid.grid_editor")

local _ = require("l10n").gettext

local MenuLayout = {}

local DEF = Config.DEFAULT_BANNER
local UI = Config.UI_LIMITS

local function grid_inset_max()
    return assert(tonumber(Config.GRID_EDGE_INSET_MAX), "config GRID_EDGE_INSET_MAX must be set")
end

local function symm_grid_margin_x_px()
    return BannerDp.symm_edge_x_dp(Settings:effectiveBanner())
end

local function symm_grid_margin_y_px()
    return BannerDp.symm_edge_y_dp(Settings:effectiveBanner())
end

local function edit_banner_number(title, read_fn, write_fn)
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
                        write_fn(n)
                    end
                    UIManager:close(dlg)
                end,
            },
        }},
    }
    UIManager:show(dlg)
    dlg:onShowKeyboard()
end

function MenuLayout.buildAppearanceSubmenu()
    require("l10n").load()
    local items = {}

    table.insert(items, {
        text = _("Widget instances (parameters)"),
        help_text = _([[Adjust per-widget parameters exposed via params.menu (defaults include the reading goal, «current book», and calendar card theme).]]),
        sub_item_table_func = function()
            return MenuWidgetInstances.build()
        end,
    })

    table.insert(items, {
        text = _("Widget corner radius (px)"),
        callback = function()
            edit_banner_number(_("Widget corner radius"), function()
                return Settings:effectiveBanner().widget_radius or DEF.widget_radius
            end, function(n)
                n = math.max(0, math.min(UI.widget_radius_px.max, math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.widget_radius = n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Widget padding (px)"),
        callback = function()
            edit_banner_number(_("Widget padding"), function()
                return Settings:effectiveBanner().widget_padding or DEF.widget_padding
            end, function(n)
                n = math.max(0, math.min(UI.widget_padding_px.max, math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.widget_padding = n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Grid horizontal inset from screen (px)"),
        help_text = _("Left/right margin between the screen border and the 6×3 grid; scaled for DPI. When unset, the combined \"legacy\" inset value is used for this axis."),
        callback = function()
            edit_banner_number(_("Grid horizontal inset (px)"), function()
                return BannerDp.symm_edge_x_dp(Settings:effectiveBanner())
            end, function(n)
                n = math.max(0, math.min(grid_inset_max(), math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.grid_edge_margin_x = n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Grid vertical inset from screen (px)"),
        help_text = _("Top/bottom margin between the screen border and the 6×3 grid; scaled for DPI. When unset, the combined \"legacy\" inset value is used for this axis."),
        callback = function()
            edit_banner_number(_("Grid vertical inset (px)"), function()
                return BannerDp.symm_edge_y_dp(Settings:effectiveBanner())
            end, function(n)
                n = math.max(0, math.min(grid_inset_max(), math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.grid_edge_margin_y = n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Grid inset: left edge (px)"),
        help_text = _("Overrides the symmetric horizontal inset for the left edge only. Matches the symmetric X value unless you customize it."),
        callback = function()
            edit_banner_number(_("Left inset (px)"), function()
                local lua = Settings:open()
                local b = lua:readSetting("banner") or {}
                local z = tonumber(b.grid_edge_margin_left)
                return z ~= nil and math.max(0, math.min(grid_inset_max(), math.floor(z))) or symm_grid_margin_x_px()
            end, function(n)
                n = math.max(0, math.min(grid_inset_max(), math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.grid_edge_margin_left = n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Grid inset: right edge (px)"),
        help_text = _("Overrides the symmetric horizontal inset for the right edge only."),
        callback = function()
            edit_banner_number(_("Right inset (px)"), function()
                local lua = Settings:open()
                local b = lua:readSetting("banner") or {}
                local z = tonumber(b.grid_edge_margin_right)
                return z ~= nil and math.max(0, math.min(grid_inset_max(), math.floor(z))) or symm_grid_margin_x_px()
            end, function(n)
                n = math.max(0, math.min(grid_inset_max(), math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.grid_edge_margin_right = n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Grid inset: top edge (px)"),
        help_text = _("Overrides the symmetric vertical inset for the top edge only."),
        callback = function()
            edit_banner_number(_("Top inset (px)"), function()
                local lua = Settings:open()
                local b = lua:readSetting("banner") or {}
                local z = tonumber(b.grid_edge_margin_top)
                return z ~= nil and math.max(0, math.min(grid_inset_max(), math.floor(z))) or symm_grid_margin_y_px()
            end, function(n)
                n = math.max(0, math.min(grid_inset_max(), math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.grid_edge_margin_top = n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Grid inset: bottom edge (px)"),
        help_text = _("Overrides the symmetric vertical inset for the bottom edge only."),
        callback = function()
            edit_banner_number(_("Bottom inset (px)"), function()
                local lua = Settings:open()
                local b = lua:readSetting("banner") or {}
                local z = tonumber(b.grid_edge_margin_bottom)
                return z ~= nil and math.max(0, math.min(grid_inset_max(), math.floor(z))) or symm_grid_margin_y_px()
            end, function(n)
                n = math.max(0, math.min(grid_inset_max(), math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.grid_edge_margin_bottom = n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Clear custom per-edge grid insets"),
        help_text = _("Remove left/right/top/bottom overrides so the symmetric values from the banner menu apply."),
        callback = function()
            BannerIO.with_banner(function(banner)
                banner.grid_edge_margin_left = nil
                banner.grid_edge_margin_right = nil
                banner.grid_edge_margin_top = nil
                banner.grid_edge_margin_bottom = nil
            end)
        end,
    })

    table.insert(items, {
        text = _("Default grid / widget gap (px)"),
        callback = function()
            edit_banner_number(_("Default gap"), function()
                return Settings:effectiveBanner().widget_gap or DEF.widget_gap
            end, function(n)
                n = math.max(0, math.min(UI.widget_gap_px.max, math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.widget_gap = n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Grid column gap (px, 0 = default gap)"),
        callback = function()
            edit_banner_number(_("Column gap"), function()
                local lua = Settings:open()
                local b = lua:readSetting("banner") or {}
                if b.grid_gutter_x ~= nil then return b.grid_gutter_x end
                return Settings:effectiveBanner().widget_gap or DEF.widget_gap
            end, function(n)
                n = math.max(0, math.min(UI.widget_gap_px.max, math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.grid_gutter_x = n == 0 and nil or n
                end)
            end)
        end,
    })

    table.insert(items, {
        text = _("Grid row gap (px, 0 = default gap)"),
        callback = function()
            edit_banner_number(_("Row gap"), function()
                local lua = Settings:open()
                local b = lua:readSetting("banner") or {}
                if b.grid_gutter_y ~= nil then return b.grid_gutter_y end
                return Settings:effectiveBanner().widget_gap or DEF.widget_gap
            end, function(n)
                n = math.max(0, math.min(UI.widget_gap_px.max, math.floor(n)))
                BannerIO.with_banner(function(banner)
                    banner.grid_gutter_y = n == 0 and nil or n
                end)
            end)
        end,
    })

    return items
end

--- Grid editor + appearance/settings submenu entries (middle of Sleepscreen widgets menu).
function MenuLayout.buildGridAndSettingsEntries()
    require("l10n").load()
    return {
        {
            text = _("Widgets grid"),
            sub_item_table_func = function()
                return GridEditor.gridZonesMenu()
            end,
        },
        {
            text = _("Settings"),
            sub_item_table_func = function()
                return MenuLayout.buildAppearanceSubmenu()
            end,
        },
    }
end

return MenuLayout

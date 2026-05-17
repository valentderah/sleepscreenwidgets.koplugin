local Settings = require("settings")

local MenuLayout = require("menu.menu_layout")

local _ = require("l10n").gettext

local MenuSleep = {}

function MenuSleep.buildEnableToggleEntry()
    require("l10n").load()
    return {
        text = _("Sleepscreen widgets"),
        help_text = _("When ON, replaces the sleep-screen banner with the 6×3 grid layout when KOReader uses Banner message mode."),
        checked_func = function()
            return Settings:isPluginEnabled()
        end,
        callback = function()
            Settings:setPluginEnabled(not Settings:isPluginEnabled())
        end,
    }
end

--- All plugin entries: enable, grid editor, settings (under one submenu).
function MenuSleep.buildSleepscreenwidgetsSubmenu(_plugin_inst)
    require("l10n").load()
    local items = {
        MenuSleep.buildEnableToggleEntry(),
    }
    local mid = MenuLayout.buildGridAndSettingsEntries()
    for i = 1, #mid do
        table.insert(items, mid[i])
    end
    return items
end

function MenuSleep.buildSleepscreenwidgetsRootEntry(plugin_inst)
    require("l10n").load()
    return {
        text = _("Sleepscreen widgets"),
        separator = true,
        sub_item_table_func = function()
            return MenuSleep.buildSleepscreenwidgetsSubmenu(plugin_inst)
        end,
    }
end

function MenuSleep.buildFallbackCombinedEntry(plugin_inst)
    return MenuSleep.buildSleepscreenwidgetsRootEntry(plugin_inst)
end

return MenuSleep

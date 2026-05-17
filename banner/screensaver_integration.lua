--[[ Hooks ScreenSaver banner area and replaces it with the grid composer layout. ]]
local BookList = require("ui/widget/booklist")
local Device = require("device")
local Screen = Device.screen

local Config = require("config")
local GridComposer = require("grid.grid_composer")
local Settings = require("settings")
local util = require("util")

local og_ui_man_show

local function merge_default_highlight()
    local HL = {}
    util.tableMerge(HL, Config.DEFAULT_HIGHLIGHT)
    HL.allowed_hl_styles = {}
    util.tableMerge(HL.allowed_hl_styles, Config.DEFAULT_HIGHLIGHT.allowed_hl_styles or {})
    return HL
end

local function find_banner_carrier(screensaver_root)
    local sw = Screen:getWidth()
    local best
    local best_w = -1
    local function visit(node, depth)
        if depth > 30 or type(node) ~= "table" then return end
        local w = node.widget
        if node.vertical_position ~= nil and node.horizontal_position ~= nil and type(w) == "table"
            and type(w.text) == "string"
        then
            local tw = w.width or sw
            if tw >= sw * 0.85 and tw > best_w then
                best_w = tw
                best = node
            end
        end
        local n = #node
        for i = 1, math.min(n, 48) do
            visit(node[i], depth + 1)
        end
    end
    visit(screensaver_root, 0)
    return best
end

local function patched_show(self, widget, ...)
    if not Settings:isPluginEnabled() then
        return og_ui_man_show(self, widget, ...)
    end

    if not widget or widget.name ~= "ScreenSaver" then
        return og_ui_man_show(self, widget, ...)
    end

    local screensaver_type = G_reader_settings:readSetting("screensaver_type")
    local message_container_enabled = G_reader_settings:isTrue("screensaver_show_message")
    local message_container_type = G_reader_settings:readSetting("screensaver_message_container")

    if not message_container_enabled or message_container_type ~= "banner" then
        return og_ui_man_show(self, widget, ...)
    end

    if screensaver_type ~= "cover"
        and screensaver_type ~= "random_image"
        and screensaver_type ~= "document_cover"
        and screensaver_type ~= "disable" then
        return og_ui_man_show(self, widget, ...)
    end

    local cus_pos_container = find_banner_carrier(widget)
    if not (cus_pos_container and cus_pos_container.widget) then
        return og_ui_man_show(self, widget, ...)
    end

    local orig_sleep_widget = cus_pos_container.widget
    local orig_sleep_text = orig_sleep_widget.text

    local placements = Settings:getGridPlacements()

    local function make_ctx()
        local screen_w, screen_h = Screen:getWidth(), Screen:getHeight()
        return {
            B_SETT = Settings:effectiveBanner(),
            HL_SETT = merge_default_highlight(),
            ui_inst = require("apps/reader/readerui").instance or require("apps/filemanager/filemanager").instance,
            last_file = G_reader_settings:readSetting("lastfile"),
            Sidecar = BookList.getDocSettings(G_reader_settings:readSetting("lastfile")),
            orig_sleep_text = orig_sleep_text or "",
            screen_w = screen_w,
            screen_h = screen_h,
            grid_inner_h = screen_h,
        }
    end

    orig_sleep_widget:free()

    local ctx = make_ctx()
    local content_widget = GridComposer.compose(placements, ctx)

    cus_pos_container.horizontal_position = 0.5
    cus_pos_container.vertical_position = 0
    cus_pos_container.widget = content_widget

    return og_ui_man_show(self, widget, ...)
end

local M = {}

function M.install()
    local UM = require("ui/uimanager")
    if UM._sleepscreenwidgets_banner_show_hook then
        return
    end
    og_ui_man_show = UM.show
    UM.show = patched_show
    UM._sleepscreenwidgets_banner_show_hook = true
end

return M

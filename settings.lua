--[[ Grid layout + banner appearance + plugin flags in LuaSettings (sleepscreenwidgets.lua). ]]
local DataStorage = require("datastorage")
local Device = require("device")
local LuaSettings = require("luasettings")
local util = require("util")

local Config = require("config")
local GridEdgeSeed = require("grid.grid_edge_seed")
local GridModel = require("grid.grid_model")
local Registry = require("banner.widgets.registry")

local SETTINGS_FILE = "sleepscreenwidgets.lua"

--- Types no longer shipped; stripped whenever grid is read or saved.
--- Single source of removed type ids — they never re-enter normalized placements.
local STALE_WIDGET_TYPES = {
    sleep_stats = true,
    today_reading = true,
    battery_status = true,
    calendar_tile = true,
    goal = true,
    weekly_activity = true,
}

local Settings = {}
Settings._lua = nil

local function strip_stale_widgets(placements)
    if type(placements) ~= "table" then
        return {}
    end
    local out = {}
    for _, p in ipairs(placements) do
        if type(p) == "table" and type(p.type) == "string" and not STALE_WIDGET_TYPES[p.type] then
            table.insert(out, p)
        end
    end
    return out
end

--- Span for GridModel; ensures widget types are registered first.
local function grid_span(type_id)
    Registry.ensure_registered()
    return Registry.default_col_span(type_id)
end

local function seed_banner_margins_when_new_grid(lua)
    local screen = Device and Device.screen
    local can_screen = screen
        and type(screen.getWidth) == "function"
        and type(screen.getHeight) == "function"
        and type(screen.scaleBySize) == "function"
    if not can_screen then
        return
    end
    local banner_for_seed = {}
    util.tableMerge(banner_for_seed, Config.DEFAULT_BANNER)
    local saved_banner = lua:readSetting("banner")
    if type(saved_banner) == "table" then
        util.tableMerge(banner_for_seed, saved_banner)
    end
    GridEdgeSeed.strip_deprecated_banner_keys_inplace(banner_for_seed)
    local seed = GridEdgeSeed.seed_margins({
        banner = banner_for_seed,
        screen_w = screen:getWidth(),
        screen_h = screen:getHeight(),
        grid_inner_h = screen:getHeight(),
        scale_by_size = function(n)
            return screen:scaleBySize(n)
        end,
    })
    if not seed.ok then
        return
    end
    local out = {}
    util.tableMerge(out, Config.DEFAULT_BANNER)
    if type(saved_banner) == "table" then
        util.tableMerge(out, saved_banner)
    end
    out.grid_edge_margin_x = seed.grid_edge_margin_x
    out.grid_edge_margin_y = seed.grid_edge_margin_y
    GridEdgeSeed.strip_deprecated_banner_keys_inplace(out)
    lua:saveSetting("banner", out)
end

--- On open: ensure `grid` blob is v3; no migration from older persistence formats.
local function bootstrap_on_open(lua)
    local raw = lua:readSetting("grid")
    local grid_ok = type(raw) == "table" and raw.grid_version == 3 and type(raw.placements) == "table"
    if not grid_ok then
        Registry.ensure_registered()
        local placements = GridModel.normalizePlacements(Config.DEFAULT_GRID_PLACEMENTS, grid_span)
        lua:saveSetting("grid", GridModel.wrapSaved(placements))
        seed_banner_margins_when_new_grid(lua)
    end
    local bn = lua:readSetting("banner")
    if type(bn) == "table" then
        GridEdgeSeed.strip_deprecated_banner_keys_inplace(bn)
        lua:saveSetting("banner", bn)
    end
    lua:flush()
end

function Settings:open()
    if self._lua then
        return self._lua
    end
    local dir = DataStorage:getSettingsDir()
    self._lua = LuaSettings:open(dir .. "/" .. SETTINGS_FILE)
    bootstrap_on_open(self._lua)
    return self._lua
end

function Settings:flush()
    if self._lua then
        self._lua:flush()
    end
end

function Settings:isPluginEnabled()
    return self:open():readSetting("plugin_enabled") ~= false
end

function Settings:setPluginEnabled(enabled)
    self:open():saveSetting("plugin_enabled", enabled and true or false)
    self:flush()
end

function Settings:effectiveBanner()
    local b = {}
    util.tableMerge(b, Config.DEFAULT_BANNER)
    util.tableMerge(b, self:open():readSetting("banner") or {})
    return b
end

function Settings:getGridPlacements()
    local raw = self:open():readSetting("grid")
    return strip_stale_widgets(GridModel.parseSaved(raw, grid_span))
end

function Settings:saveGridPlacements(placements)
    placements = strip_stale_widgets(placements)
    local norm = GridModel.normalizePlacements(placements, grid_span)
    self:open():saveSetting("grid", GridModel.wrapSaved(norm))
    self:flush()
end

return Settings

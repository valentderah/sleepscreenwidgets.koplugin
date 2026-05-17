--[[ Defaults for sleepscreenwidgets plugin. ]]
local Config = {}

local ActivityRegister = require("banner.widgets.activity.register")
local ReadingNowRegister = require("banner.widgets.reading_now.register")
local CalendarRegister = require("banner.widgets.calendar.register")

local activity_week_dark = ActivityRegister.clone_default_params()
activity_week_dark.variant = "week"
activity_week_dark.card_theme = "dark"
activity_week_dark.col_span = 3

--- Bump when persisted settings shape changes; `Settings:open` re-writes `grid` from v2 or clears to empty.
Config.SCHEMA_VERSION = 11

Config.GRID_EDGE_INSET_MAX = 512

--- Composer geometry (screen px before scale where noted; see also DEFAULT_BANNER).
Config.GRID_LAYOUT = {
    --- Minimum inner width/height used for slot math after edge insets.
    inner_min_px = 30,
    --- Minimum square side / span≥2 content box (after card padding).
    cell_content_min_px = 20,
    --- zone_index encoding: row * factor + anchor_col (see grid_editor if changed).
    zone_tag_row_multiplier = 10,
}

--- Clamps for Banner appearance menu (logical px unless noted).
Config.UI_LIMITS = {
    widget_radius_px = { max = 48 },
    widget_padding_px = { max = 32 },
    widget_gap_px = { max = 24 },
}

--- @param extra table|nil merged into base (e.g. `{ col_span = 3 }` for the shipped default grid)
function Config.default_reading_now_widget_params(extra)
    return ReadingNowRegister.clone_default_params(extra)
end

function Config.default_calendar_widget_params()
    return CalendarRegister.clone_default_params()
end

--- Digital clock row (grid editor “add clock”); not used in `DEFAULT_GRID_PLACEMENTS` (that slot is `datetime`).
function Config.default_digital_clock_params()
    return {
        variant = "digital",
        format = "%H:%M",
        font_face = "cfont",
        font_size = 22,
    }
end

function Config.default_template_widget_params()
    return { pattern = "%T", role = "title" }
end

--- Initial grid when `grid` is absent from settings (first open). Grid is 3 cols × 6 rows (see GridModel).
Config.DEFAULT_GRID_PLACEMENTS = {
    { type = "datetime", params = {}, row = 1, col = 1 },
    { type = "reading_now", params = Config.default_reading_now_widget_params({ col_span = 3 }), row = 2, col = 1 },
    { type = "highlight", params = { col_span = 2 }, row = 3, col = 1 },
    { type = "calendar", params = Config.default_calendar_widget_params(), row = 3, col = 3 },
    { type = "activity", params = activity_week_dark, row = 4, col = 1 },
}

Config.DEFAULT_BANNER = {
    title_fontFace = "cfont",
    title_fontSize = 30,
    stats_fontFace = "cfont",
    stats_fontSize = 17,
    background = 0,
    widget_radius = 12,
    widget_padding = 16,
    widget_gap = 6,
    grid_edge_margin_x = 100,
    grid_edge_margin_y = 100,
}

--[[ Developer note: banner unit semantics (avoid mixing models):
    • grid_edge_margin_* and grid_edge_margin[_xy]: logical dp-like integers; scaled via
      Screen:scaleBySize at layout boundary (see grid.banner_dp / layout_spec).
    • widget_radius, widget_padding, widget_gap, grid_gutter_*: stored as today’s menu
      saves them (see menu/menu_layout.lua clamps); behaviour unchanged in simplification pass.
]]

Config.DEFAULT_HIGHLIGHT = {
    showRandomHighlight = true,
    highlight_fontFace = "NotoSerif-Italic.ttf",
    highlight_fontSize = 16,
    justify = true,
    add_quotations = true,
    show_accent_line = true,
    showHighlightFooter = true,
    hl_footer_fontFace = "NotoSerif-Regular.ttf",
    hl_footer_fontSize = 15,
    hl_footer_text = "saved on %DT at %HM",
    allowed_hl_styles = {
        lighten = true,
        underscore = true,
        strikethrough = false,
        invert = false,
    },
}

return Config

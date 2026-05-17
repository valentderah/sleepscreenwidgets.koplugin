-- Run from KOReader-compatible LuaJIT (ffi + blitbuffer), например профилем KOReader или его unit harness.
package.path = package.path .. ";./?.lua"

local function assert_same_ref(a, b, m)
    if a ~= b then
        error(m or "blitbuffer ref mismatch")
    end
end

local FrameStyle = require("banner.frame_style")
local CT = assert(require("banner.card_theme"))
local Contract = require("banner.card_palette_contract")

local function assert_palette_complete(p, label)
    local miss = Contract.missing_keys(p)
    if #miss > 0 then
        error(label .. ": missing keys: " .. table.concat(miss, ", "))
    end
end

do
    local empty_miss = Contract.missing_keys({})
    if #empty_miss == 0 then
        error("expected missing_keys({}) to report all required keys")
    end
end

local L = FrameStyle.card_colors_light()
local D = FrameStyle.card_colors_dark_tile()

local lp = CT.palette_for_placement("reading_now", { card_theme = "light" })
local dp = CT.palette_for_placement("reading_now", { card_theme = "dark" })
assert_same_ref(lp.fill, L.fill, "reading_now light fill")
assert_same_ref(dp.fill, D.fill, "reading_now dark fill")

local inh_cal = CT.palette_for_placement("calendar", {})
assert_same_ref(inh_cal.fill, L.fill, "calendar inherit/absent defaults light")

local light_cal = CT.palette_for_placement("calendar", { card_theme = "light" })
assert_same_ref(light_cal.fill, L.fill, "calendar light fill")

local dark_cal = CT.palette_for_placement("calendar", { card_theme = "dark" })
assert_same_ref(dark_cal.fill, D.fill, "calendar dark fill")

assert_palette_complete(lp, "palette reading_now light")
assert_palette_complete(dp, "palette reading_now dark")
assert_palette_complete(inh_cal, "palette calendar default light")
assert_palette_complete(light_cal, "palette calendar light")
assert_palette_complete(dark_cal, "palette calendar dark")

local analog_clock = CT.palette_for_placement("clock", { variant = "analog" })
assert_palette_complete(analog_clock, "palette clock analog (forced dark tile)")
assert_same_ref(analog_clock.fill, D.fill, "clock analog uses dark tile fill")

local digital_clock = CT.palette_for_placement("clock", { variant = "digital", card_theme = "light" })
assert_palette_complete(digital_clock, "palette clock digital light")
assert_same_ref(digital_clock.fill, L.fill, "clock digital light fill")

local digital_clock_dark = CT.palette_for_placement("clock", { variant = "digital", card_theme = "dark" })
assert_palette_complete(digital_clock_dark, "palette clock digital dark")
assert_same_ref(digital_clock_dark.fill, D.fill, "clock digital dark fill")

assert_palette_complete(L, "card_colors_light")
assert_palette_complete(D, "card_colors_dark_tile")

print("card_theme_test: OK")

--[[ Persist minimal per-slot daily outcomes for streak; throttles writes.]]
local Settings = require("settings")
local JM = require("banner.widgets.activity.journal_math")

local M = {}

local JOURNAL_KEY = "goal_slot_journal"
local LAST_FLUSH_TS = {}

local MIN_FLUSH_INTERVAL_SEC = 75

local function journal_table()
    local j = Settings:open():readSetting(JOURNAL_KEY)
    if type(j) ~= "table" then
        return {}
    end
    return j
end

local function save_journal_entire(tbl)
    Settings:open():saveSetting(JOURNAL_KEY, tbl)
    Settings:flush()
end

local function normalized_slot_key(ctx)
    local r = math.floor(tonumber(ctx.placement_row) or 0)
    local c = math.floor(tonumber(ctx.placement_col) or 0)
    if r < 1 or c < 1 then
        return nil
    end
    return tostring(r) .. "_" .. tostring(c)
end

function M.persist_and_streak(slot_key, goal_minutes, goal_pages, read_minutes, read_pages)
    if not slot_key then
        return 0
    end
    if not JM.has_active_goal(goal_minutes, goal_pages) then
        return 0
    end
    local success = JM.targets_met_today(read_minutes, read_pages, goal_minutes, goal_pages)
    local today_iso = JM.today_iso()
    local jfull = journal_table()

    local slot = jfull[slot_key]
    if type(slot) ~= "table" then
        slot = {}
        jfull[slot_key] = slot
    end
    slot.days = type(slot.days) == "table" and slot.days or {}

    local prev_known = slot.days[today_iso]
    local rollover = slot.last_calendar_day ~= nil and slot.last_calendar_day ~= today_iso
    slot.last_calendar_day = today_iso

    slot.days[today_iso] = success
    JM.prune_daily_map(slot.days, today_iso, 400)

    local streak = JM.streak_from_daily_map(slot.days, today_iso)

    local now = os.time()
    local urgency = rollover or prev_known ~= success
    local last = tonumber(LAST_FLUSH_TS[slot_key]) or 0
    if urgency or now - last >= MIN_FLUSH_INTERVAL_SEC then
        save_journal_entire(jfull)
        LAST_FLUSH_TS[slot_key] = now
    end

    return streak
end

function M.slot_streak_from_build(params, ctx, read_minutes, read_pages)
    local gm = math.max(0, math.floor(tonumber(params.daily_goal_minutes) or 0))
    local gp = math.max(0, math.floor(tonumber(params.daily_goal_pages) or 0))
    local key = normalized_slot_key(ctx)
    return M.persist_and_streak(key, gm, gp, read_minutes, read_pages), key
end

return M

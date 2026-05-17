--[[
    Remaining reading time for the foreground book using ReaderStatistics.avg_time.
    ReaderStatistics is registered as `ReaderUI.registerModule("statistics", ...)`; the module
    is exposed as `reader_ui.statistics`. After registration, KOReader sets the widget's
    `name` to `"readerstatistics"` (`"reader" .. module_name`), so tree walks must not look
    only for `"statistics"` (see `frontend/apps/reader/readerui.lua` registerModule).
]]

local MAX_NODES = 120

local M = {}

--- Page count: sidecar `doc_pages`, else live `document:getPageCount()` (matches reading_now UI).
function M.total_pages_best_effort(ui)
    if not ui or not ui.document then
        return 0
    end
    local ds = ui.doc_settings and ui.doc_settings.data or {}
    local total = math.floor(tonumber(ds.doc_pages) or 0)
    if total > 0 then
        return total
    end
    if type(ui.document.getPageCount) == "function" then
        local ok, n = pcall(function()
            return ui.document:getPageCount()
        end)
        if ok and type(n) == "number" and n > 0 then
            return math.floor(n)
        end
    end
    return 0
end

local function is_statistics_plugin_node(node)
    if type(node) ~= "table" then
        return false
    end
    local nm = node.name
    -- Class default is "statistics"; ReaderUI renames to "readerstatistics".
    return nm == "statistics" or nm == "readerstatistics"
end

local function find_statistics(reader_ui)
    if type(reader_ui) ~= "table" then
        return nil
    end
    -- Fast path: ReaderUI stores the plugin instance here.
    local direct = reader_ui.statistics
    if type(direct) == "table" and tonumber(direct.avg_time) and tonumber(direct.avg_time) > 0 then
        return direct
    end
    local queue = {}
    local seen = {}
    local function push(w)
        if type(w) == "table" and not seen[w] then
            seen[w] = true
            queue[#queue + 1] = w
        end
    end
    push(reader_ui)
    local head = 1
    local examined = 0
    while head <= #queue do
        examined = examined + 1
        if examined > MAX_NODES then
            break
        end
        local node = queue[head]
        head = head + 1
        if is_statistics_plugin_node(node) and type(node.avg_time) == "number" and tonumber(node.avg_time) > 0 then
            return node
        end
        if type(node) ~= "table" then
            -- continue
        else
            push(node.widget)
            for i = 1, #node do
                push(node[i])
            end
            if type(node.keyboard) == "table" then
                push(node.keyboard)
            end
        end
    end
    return nil
end

local function estimate_minutes(reader_ui)
    local st = find_statistics(reader_ui)
    local avg_page = tonumber(st and st.avg_time)
    if not avg_page or avg_page <= 0 then
        return nil
    end
    local ui = reader_ui
    if not ui or not ui.document then
        return nil
    end
    local page = 1
    if ui.view and ui.view.state and tonumber(ui.view.state.page) then
        page = math.floor(ui.view.state.page)
    end
    local total = M.total_pages_best_effort(ui)
    if total <= 0 then
        return nil
    end
    page = math.max(1, math.min(page, total))
    local remaining = math.max(0, total - page)
    local seconds = avg_page * remaining
    local minutes = math.ceil(seconds / 60)
    if minutes <= 0 then
        return 0
    end
    return math.min(minutes, 60 * 24 * 365)
end

function M.remaining_minutes_best_effort(reader_ui)
    local ok, m = pcall(estimate_minutes, reader_ui)
    if ok and type(m) == "number" then
        return m
    end
    return nil
end

return M

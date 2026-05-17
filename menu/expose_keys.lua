local M = {}

function M.expose_ordered_keys(exposes, order)
    local keys = {}
    local seen = {}
    if type(order) == "table" then
        for _, k in ipairs(order) do
            if exposes[k] == true then
                table.insert(keys, k)
                seen[k] = true
            end
        end
    end
    local rest = {}
    for k, v in pairs(exposes) do
        if v == true and not seen[k] then
            table.insert(rest, k)
        end
    end
    table.sort(rest)
    for _, k in ipairs(rest) do
        table.insert(keys, k)
    end
    return keys
end

return M

package.path = package.path .. ";./?.lua"

local function assert_eq_list(a, b, m)
    if #a ~= #b then
        error((m or "len") .. ": " .. #a .. " vs " .. #b)
    end
    for i = 1, #a do
        if a[i] ~= b[i] then
            error((m or "idx") .. " " .. i .. ": " .. tostring(a[i]) .. " vs " .. tostring(b[i]))
        end
    end
end

local EK = assert(require("menu.expose_keys"))

assert_eq_list(
    EK.expose_ordered_keys({ b = true, a = true }, { "b", "a" }),
    { "b", "a" },
    "order"
)

assert_eq_list(
    EK.expose_ordered_keys({ z = true, m = true }, {}),
    { "m", "z" },
    "alpha"
)

print("expose_keys_test: OK")

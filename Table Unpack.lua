rconsoleclear()
function serializeTable(a, b, c, d)
    c = c or false
    d = d or 0
    local e = string.rep("     ", d)
    if b then
        e = e .. b .. " = "
    end
    if type(a) == "table" then
        e = e .. "{" .. (not c and "\n" or "")
        for f, g in pairs(a) do
            e = e .. serializeTable(g, f, c, d + 1) .. "," .. (not c and "\n" or "")
        end
        e = e .. string.rep("    ", d) .. "}"
    elseif type(a) == "number" then
        e = e .. tostring(a)
    elseif type(a) == "string" then
        e = e .. string.format("%q", a)
    elseif type(a) == "boolean" then
        e = e .. (a and "true" or "false")
    elseif type(a) == "function" then
        e = e .. "func: " .. debug.getinfo(a).name
    else
        e = e .. tostring(a)
    end
    return e
end

rconsoleprint(serializeTable())

--[[
bv require(game:GetService("Players").LocalPlayer.PlayerGui.Main.MainClient.PlayerDataClient).Data

rconsoleprint(serializeTable(require(game:GetService("Players").LocalPlayer.PlayerGui.Main.MainClient.PlayerDataClient).Data))
--]]
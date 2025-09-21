import "Dandiron.RpFilter.ColorUtils"

PlayerQueue = {}

local MAX_SIZE = 13

local players = {
--[[
    ["Alice"] = {
        name = "Alice",
        color = {red=0, green=0, blue=0},
        prev = nil,
        next = nil,
    }
]]
}
local first
local last
local size = 0

local function getShiftFactor(n)
    return n % 2 == 0 and n/2 or -(n + 1)/2
end

function PlayerQueue.insert(name, baseColor)
    local newPlayer = {name = name, next = nil}

    if players[name] ~= nil then
        local player = players[name]

        if first == player then first = player.next end
        if last == player then last = player.prev end
        if player.next ~= nil then player.next.prev = player.prev end
        if player.prev ~= nil then player.prev.next = player.next end

        players[name] = nil
        size = size - 1
    elseif size == 0 then
        first = newPlayer
    elseif size == MAX_SIZE then
        newPlayer.color = first.color
        local temp = first.next
        first.next.prev = nil
        players[first.name] = nil
        first = temp
        size = size - 1
    end

    newPlayer.color = newPlayer.color or AdjustHsl(baseColor, {h = 2/13 * getShiftFactor(size)})
    newPlayer.prev = last
    players[name] = newPlayer
    size = size + 1

    if last ~= nil then last.next = newPlayer end
    last = newPlayer
end

---@param name string
---@return table
function PlayerQueue.getColor(name)
    return players[name].color
end

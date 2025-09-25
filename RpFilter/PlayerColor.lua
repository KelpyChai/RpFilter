import "Dandiron.RpFilter.ColorUtils"

PlayerColor = {}

local MAX_NUM_PLAYERS = 13

local numPlayers = 1
local first, last
local players = {
--[[
    ["Alice"] = {
        name = "Alice",
        color = {red = 0, green = 0, blue = 0},
        prev = nil,
        next = nil,
    }
]]
}

local isColorLight = false
local currEmoter

local function getShiftFactor(n)
    return n % 2 == 0 and n/2 or -(n + 1)/2
end

-- Inconsistent if emoteColor is changed during session
local function updateRainbowColor(name, baseColor)
    if name == LOCAL_PLAYER_NAME then return end

    local newPlayer = {name = name, next = nil}

    if players[name] ~= nil then
        local player = players[name]
        newPlayer.color = player.color

        if first == player then first = player.next end
        if last == player then last = player.prev end
        if player.next ~= nil then player.next.prev = player.prev end
        if player.prev ~= nil then player.prev.next = player.next end

        players[name] = nil
        numPlayers = numPlayers - 1
    elseif numPlayers == 1 then
        first = newPlayer
    elseif numPlayers == MAX_NUM_PLAYERS then
        newPlayer.color = first.color
        local temp = first.next
        first.next.prev = nil
        players[first.name] = nil
        first = temp
        numPlayers = numPlayers - 1
    end

    newPlayer.color = newPlayer.color or AdjustHsl(baseColor, {h = 2/13 * getShiftFactor(numPlayers)})
    newPlayer.prev = last
    players[name] = newPlayer
    numPlayers = numPlayers + 1

    if last ~= nil then last.next = newPlayer end
    last = newPlayer
end

local function updateContrastColor(playerName)
    if playerName ~= currEmoter then
        currEmoter = playerName
        isColorLight = not isColorLight
    end
end

local function copy(color)
    return {red = color.red, green = color.green, blue = color.blue}
end

local function getRainbowColor(name, emoteColor)
    return name == LOCAL_PLAYER_NAME and emoteColor or copy(players[name].color)
end

local function getContrastColor(emoteColor, isLighter)
    local lighterColor = AdjustHsl(emoteColor, {h = -0.014, l = 0.01})
    local darkerColor = AdjustHsl(emoteColor, {h = 0.014, l = -0.008})
    return isLighter and lighterColor or darkerColor
end

function PlayerColor.update(playerName, emoteColor, options)
    if options.areEmotesRainbow then
        updateRainbowColor(playerName, emoteColor)
    elseif options.areEmotesContrasted then
        updateContrastColor(playerName)
    end
end

function PlayerColor.get(playerName, emoteColor, options)
    if options.areEmotesRainbow then
        return getRainbowColor(playerName, emoteColor)
    elseif options.areEmotesContrasted then
        return getContrastColor(emoteColor, isColorLight)
    else
        return emoteColor
    end
end

-- Assumption: user has Regional or OOC enabled

import "Dandiron.RpFilter.TextUtils"

Location = {}

local LOCATION_PATTERNS = {
    "^(Entered) the (.-) %- (Regional) channel%.$",
    "^(Entered) the (.-) %- (OOC) channel%.$",
    "^(Left) the (.-) %- (Regional) channel%.$",
    "^(Left) the (.-) %- (OOC) channel%.$"
}
local INSTANCE = "instance"

local currLocation = INSTANCE
local currChannels = {}

function Location.getCurrent()
    return currLocation
end

function Location.isInstanced()
    return currLocation == INSTANCE
end

function Location.setCurrent(newLocation)
    if Location.isInstanced() then
        currLocation = newLocation
    end
end

---@param message string
---@return {action: string, region: string, channel: string}|nil
local function getLocationInfo(message)
    for _, pattern in ipairs(LOCATION_PATTERNS) do
        local action, region, channel = message:match(pattern)
        if channel then
            return {action = action, region = region, channel = channel}
        end
    end
    return nil
end

---Parses standard channel for Entered/Left messages to keep track of location
---@param message string
function Location.update(message)
    local info = getLocationInfo(Strip(message))
    if not info then return end
    local action, region, channel = info.action, info.region, info.channel

    if action == "Entered" then
        currChannels[channel] = true
        currLocation = region
    else
        currChannels[channel] = nil
        if next(currChannels) == nil then
            currLocation = INSTANCE
        end
    end
end

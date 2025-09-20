-- Assumption: user has Regional or OOC enabled

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

function Location:getCurrent()
    return currLocation
end

function Location:setCurrent(newLocation)
    currLocation = newLocation
end

local function getLocationInfo(message)
    for _, pattern in ipairs(LOCATION_PATTERNS) do
        local action, region, channel = message:match(pattern)
        if channel then
            return action, region, channel
        end
    end
    return nil
end

---Parses standard channel for Entered/Left messages to keep track of location
---@param message string
function Location:updateIfChanged(message)
    local action, region, channel = getLocationInfo(message)
    if not channel then return end

    if action == "Entered" then
        currChannels[channel] = true
        if self:getCurrent() ~= region then
            self:setCurrent(region)
        end
    else
        currChannels[channel] = nil
        if next(currChannels) == nil then
            self:setCurrent(INSTANCE)
        end
    end
end

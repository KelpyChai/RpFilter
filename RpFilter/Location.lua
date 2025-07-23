-- Assumption: user has Regional or OOC enabled

Location = {
    INSTANCE = "instance",
    Channels = {},
}
Location._current = Location.INSTANCE

function Location:getCurrent()
    return self._current
end

function Location:setCurrent(newLocation)
    self._current = newLocation
    print("Now entering " .. newLocation)
end

function Location:isInstanced()
    return self:getCurrent() == self.INSTANCE
end

---Parses standard channel for Entered/Left messages to keep track of location
---@param message string
function Location:updateIfChanged(message)
    local info = self:getLocationInfo(message)

    if not info then return end
    local action, region, channel = info.action, info.region, info.channel

    if action == "Entered" then
        self.Channels[channel] = true
        if self:getCurrent() ~= region then
            self:setCurrent(region)
        end
    else
        self.Channels[channel] = nil
        if next(self.Channels) == nil then
            self:setCurrent(self.INSTANCE)
        end
    end
end

local patterns = {
    "^(Entered) the (.-) %- (Regional) channel%.$",
    "^(Entered) the (.-) %- (OOC) channel%.$",
    "^(Left) the (.-) %- (Regional) channel%.$",
    "^(Left) the (.-) %- (OOC) channel%.$"
}

function Location:getLocationInfo(message)
    local action, region, channel
    for _, pattern in ipairs(patterns) do
        action, region, channel = message:match(pattern)
        if channel ~= nil then
            return {action = action, region = region, channel = channel}
        end
    end
    return nil
end

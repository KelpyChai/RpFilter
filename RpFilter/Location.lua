-- Assumption: user has Regional or OOC enabled

Location = {
    INSTANCE = "instance",
    channels = {},
}
Location._current = Location.INSTANCE

function Location:getCurrent()
    return self._current
end

function Location:setCurrent(newLocation)
    self._current = newLocation
    Say.currentBlockedNpcs = Say:getBlockedNpcs(newLocation)

    -- Debugging
    -- print("Now entering " .. newLocation)
    -- print("Blocked NPCs:")
    -- if Say.CurrentBlockedNpcs then
    --     for name, _ in pairs(Say.CurrentBlockedNpcs) do
    --         print(name)
    --     end
    -- else
    --     print("None")
    -- end
end

function Location:isInstanced()
    return self:getCurrent() == self.INSTANCE
end

-- TODO: Use string.sub() to reduce pattern matching

local function getLocationInfo(message)
    local patterns = {
        "^(Entered) the (.-) %- (Regional) channel%.$",
        "^(Entered) the (.-) %- (OOC) channel%.$",
        "^(Left) the (.-) %- (Regional) channel%.$",
        "^(Left) the (.-) %- (OOC) channel%.$"
    }

    for _, pattern in ipairs(patterns) do
        local action, region, channel = message:match(pattern)
        if channel then
            return {action = action, region = region, channel = channel}
        end
    end
    return nil
end

---Parses standard channel for Entered/Left messages to keep track of location
---@param message string
function Location:updateIfChanged(message)
    local info = getLocationInfo(message)

    if not info then return end
    local action, region, channel = info.action, info.region, info.channel

    if action == "Entered" then
        self.channels[channel] = true
        if self:getCurrent() ~= region then
            self:setCurrent(region)
        end
    else
        self.channels[channel] = nil
        if next(self.channels) == nil then
            self:setCurrent(self.INSTANCE)
        end
    end
end

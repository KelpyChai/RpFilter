-- FIXME: Make assumption about whether user will enable/disable channels

TimeNow = Turbine.Engine.GetGameTime

Location = {
    -- Implies that regional channels are disabled
    UNKNOWN = "unknown",
    INSTANCE = "instance",
    -- TODO: Obtain the maximum delay possible
    INSTANCE_START_DELAY = 3,
    lastKnownTime = nil,
    Channels = {},
    -- Add instances to this set if dialogue is misfiltered
    _InstanceQuests = {
        ["A Flurry of Fireworks"] = true
    },
}
Location._current = Location.UNKNOWN

function Location:getCurrent()
    return self._current
end

function Location:setCurrent(newLocation)
    self._current = newLocation

    if self:isUnknown() then
        print("Location is now unknown")
    else
        print("Now entering " .. newLocation)
    end
end

function Location:isUnknown()
    return self:getCurrent() == self.UNKNOWN
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
        -- The client exits all regional channels when entering instance
        if next(self.Channels) == nil then
            if self:getCurrent() ~= self.INSTANCE then
                self:setCurrent(self.UNKNOWN)
            end
            self.lastKnownTime = TimeNow()
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

---Parses quest channel to track entry of instances
---@param message string
function Location:updateIfInstanced(message)
    if self:hasEnteredInstance(message) and self:isRegionalChannelEnabled() then
        self:setCurrent(self.INSTANCE)
    end
end

---Check whether regional channels were left automatically or disabled manually.
---Assumes users will not enter instance immediately after disabling.
function Location:isRegionalChannelEnabled()
    return self.lastKnownTime ~= nil and TimeNow() - self.lastKnownTime < self.INSTANCE_START_DELAY
end

function Location:hasEnteredInstance(message)
    -- FIXME: Find out why questless instances don't work
    if message:match("^<u>.-</u>$") then
        -- This message is sent before regional channels update
        -- So it needs to call setCurrent directly
        self:setCurrent(self.INSTANCE)
        return false
    end

    local newQuest = message:match("^New Quest: (.+)")

    if not newQuest then
        return false
    elseif newQuest:match("^Instance:") or
           newQuest:match("^Challenge:") or
           newQuest:match("^Raid:") or
           newQuest:match("^Featured ") or
           newQuest:match("Tier %d$") then
        return true
    else
        return self._InstanceQuests[newQuest] ~= nil
    end
end

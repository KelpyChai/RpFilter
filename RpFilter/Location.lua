-- FIXME: Make assumption about whether user will enable/disable channels

TimeNow = Turbine.Engine.GetGameTime

Location = {
    UNKNOWN = "Unknown", -- Implies that regional channels are disabled
    INSTANCE = "Instance",
    -- TODO: Obtain the maximum delay possible
    INSTANCE_START_DELAY = 3,
    _current = Location.UNKNOWN,
    _Channels = {},
    lastKnownTime = nil,
}

-- TODO: Obtain instance names and prefixes

Location._InstanceQuests = {
    ["A Flurry of Fireworks"] = true
}

function Location:getCurrent()
    return self._current
end

function Location:isUnknown()
    return self._current == self.UNKNOWN
end

function Location:isInstanced()
    return self._current == self.INSTANCE
end

function Location:updateIfChanged(message)
    local action, region, channel = self:getLocationInfo(message)

    if not channel then return end

    if action == "Entered" then
        self._Channels[channel] = true
        self._current = region
    else
        self._Channels[channel] = nil
        -- The client exits all regional channels when changing location
        if next(self._Channels) == nil then
            self._current = self.UNKNOWN
            self.lastKnownTime = TimeNow()
        end
    end
end

function Location:getLocationInfo(message)
    return message:match("^(Entered|Left) the (.-) - (Regional|OOC) channel.$")
end

function Location:updateIfInstanced(message)
    if self:hasEnteredInstance(message) and self:isRegionalChannelEnabled() then
        self._current = self.INSTANCE
    end
end

---Check whether regional channels were left automatically or disabled manually.
---Assumes users will not enter instance immediately after disabling.
function Location:isRegionalChannelEnabled()
    return self.lastKnownTime ~= nil and TimeNow() - self.lastKnownTime < self.INSTANCE_START_DELAY
end

function Location:hasEnteredInstance(message)
    if message:match("^<u>.-</u>$") then
        return true
    end

    if message:sub(1, 11) ~= "New Quest: " then
        return false
    else
        local newQuest = message:sub(12)
        if newQuest:match("^(Instance|Challenge|Raid|Featured Instance)") then
            return true
        else
            return self._InstanceQuests[newQuest] ~= nil
        end
    end
end

-- FIXME: Make assumption about whether user will enable/disable channels

Location = {
    UNKNOWN = "Unknown", -- For when location channels are disabled
    INSTANCE = "Instance",
    _current = Location.UNKNOWN,
    _Channels = {},
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
        self._current = region
        self._Channels[channel] = true
    else
        -- Either moving or disabling channel
        self._Channels[channel] = nil
        if next(self._Channels) == nil then
            self._current = self.UNKNOWN
            -- TODO: Add a callback with one second timeout -> self._current = self.INSTANCE
            -- To bypass the check in updateIfInstanced()
        end
    end
end

function Location:getLocationInfo(message)
    return message:match("^(Entered|Left) the (.-) - (Regional|OOC) channel.$")
end

function Location:updateIfInstanced(message)
    -- Do not set location to Instance if channels are disabled
    if self:isUnknown() then return end

    if self:hasEnteredInstance(message) then
        self._current = self.INSTANCE
    end
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

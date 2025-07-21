-- FIXME: Make assumption about whether user will enable/disable channels

Location = {
    UNKNOWN = "Unknown", -- For when location channels are disabled
    INSTANCE = "Instance",
    current = Location.UNKNOWN,
    Channels = {},
}

-- TODO: Obtain instance names and prefixes

Location.InstanceQuests = {
    ["A Flurry of Fireworks"] = true
}

function Location:isUnknown()
    return self.current == self.UNKNOWN
end

function Location:isInstanced()
    return self.current == self.INSTANCE
end

function Location:updateIfChanged(message)
    local action, region, channel = self:getLocationInfo(message)

    if not channel then return end

    if action == "Entered" then
        self.current = region
        self.Channels[channel] = true
    else
        -- Either moving or disabling channel
        self.Channels[channel] = nil
        if next(self.Channels) == nil then
            self.current = self.UNKNOWN
            -- TODO: Add a callback with one second timeout -> self.current = self.INSTANCE
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
        self.current = self.INSTANCE
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
            return self.InstanceQuests[newQuest]
        end
    end
end

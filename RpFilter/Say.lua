Say = {
    CurrentBlockedNpcs = nil,
    -- CurrentBlockedSays = nil,
}

Say._BlockedNpcs = {
    ["Bree-land"] = {
        ["Townsperson"] = true,
        ["Woodcutter"] = true,
        ["Bounder"] = true,
        ["Tom Bombadil"] = true,
        -- ["Lalia"] = true,
        -- ["Constable Bolger"] = true,
    },

    ["Bree-town"] = {
        ["Townsperson"] = true,
        ["Prisoner"] = true,
        ["Minstrel"] = true,
        ["Farmer"] = true,
        ["Jim Skinner"] = true,
        ["Drunken Reveller"] = true,
    },

    ["Shire"] = {
        ["Townsperson"] = true,
        ["Drunkard"] = true,
        ["Iris Goodbody"] = true,
    },

    ["Ered Luin"] = {
        ["Fisherman"] = true,
        ["Dockworker"] = true,
        ["Traveller"] = true,
    },

    ["Thorin's Hall"] = {
        ["Watcher"] = true,
    },

    ["Lone-lands"] = {
        ["Waitress"] = true,
        ["Whittler"] = true,
        ["Patron"] = true,
    },

    ["North Downs"] = {
        ["Ranger"] = true,
        ["Miner"] = true,
        ["Smith"] = true,
        ["Dúrlammad"] = true,
        -- ["Idalene"] = true,
    },
}

function Say:getBlockedNpcs(region)
    return self._BlockedNpcs[region]
end

---Filters NPC chatter from the say channel
---@param message any
---@return boolean
function Say:isAllowed(message)
    local id, name = message:match("^<Select:IID:(0x%x-)>(.-)<\\Select>")

    if not id then
        return self:isFromLocalPlayer(message)
    elseif self:isFromNpc(id) then
        return self:isNpcAllowed(name)
    else
        -- Must be from another player
        return true
    end
end

function Say:isNpcAllowed(name)
    if not self.CurrentBlockedNpcs or Location:isInstanced() then
        return true
    else
        return not self.CurrentBlockedNpcs[name]
    end
end

function Say:isFromLocalPlayer(message)
    return message:sub(1, 8) == "You say,"
end

function Say:isFromNpc(id)
    -- "0x0346"
    return id:sub(1, 11) == "0x034600005"
end

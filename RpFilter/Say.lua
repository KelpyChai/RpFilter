Say = {
    currentBlockedNpcs = {},
    -- currentBlockedSays = {},
}

Say._blockedNpcs = {
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
        ["Hugh Reed"] = true,
        ["Jim Skinner"] = true,
        ["Drunken Reveller"] = true,
        ["Maud Foxglove"] = true,
        ["Tad Gardener"] = true,
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
        ["Miner"] = true,
        ["Labourer"] = true,
    },

    ["Lone-lands"] = {
        ["Waitress"] = true,
        ["Whittler"] = true,
        ["Patron"] = true,
        ["Belinda Rosewater"] = true,
    },

    ["North Downs"] = {
        ["Ranger"] = true,
        ["Miner"] = true,
        ["Smith"] = true,
        ["Dúrlammad"] = true,
        ["Anne Rumsey"] = true,
        -- ["Idalene"] = true,
    },

    ["Trollshaws"] = {
        ["Aegúrel"] = true,
    },
}

function Say:getBlockedNpcs(region)
    return self._blockedNpcs[region]
end

local function isFromLocalPlayer(message)
    return message:sub(1, 8) == "You say," or message:sub(1, 10) == "You shout,"
end

local function isFromNpc(id)
    return id:sub(1, 6) == "0x0346"
end

function Say:isNpcAllowed(name)
    if not self.currentBlockedNpcs or Location:isInstanced() then
        return true
    else
        return not self.currentBlockedNpcs[name]
    end
end

---Filters NPC chatter from the say channel
---@param message any
---@return boolean
function Say:isAllowed(message)
    local id, name = message:match("^<Select:IID:(0x%x-)>(.-)<\\Select>")

    if not id then
        return isFromLocalPlayer(message)
    elseif isFromNpc(id) then
        return self:isNpcAllowed(name)
    else
        -- Must be from another player
        return true
    end
end

function Say:format(say)
    return UnderlineAsterisks(say):gsub("%-%-", "—")
end

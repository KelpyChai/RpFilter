Say = {}

Say._Blocklist = {
    ["Drunkard"]    = {["Shire"] = true},
    ["Townsperson"] = {["Shire"] = true, ["Bree-land"] = true, ["Bree-town"] = true},
    ["Fisherman"]   = {["Ered Luin"] = true},
    ["Dockworker"]  = {["Ered Luin"] = true},
    ["Traveller"]   = {["Ered Luin"] = true},
    ["Watcher"]     = {["Thorin's Hall"] = true},
    ["Woodcutter"]  = {["Bree-land"] = true},
    ["Bounder"]     = {["Bree-land"] = true},
    ["Lalia"]       = {["Bree-land"] = true},
    ["Prisoner"]    = {["Bree-town"] = true},
    ["Minstrel"]    = {["Bree-town"] = true},
    ["Farmer"]      = {["Bree-town"] = true},
    ["Waitress"]    = {["Lone-lands"] = true},
    ["Whittler"]    = {["Lone-lands"] = true},
    ["Patron"]      = {["Lone-lands"] = true},
    ["Idalene"]     = {["North Downs"] = true},
    ["Ranger"]      = {["North Downs"] = true},
    ["Dúrlammad"]   = {["North Downs"] = true},
    ["Miner"]       = {["North Downs"] = true},
    ["Smith"]       = {["North Downs"] = true},
    ["Iris Goodbody"]       = {["Shire"] = true},
    ["Tom Bombadil"]        = {["Bree-land"] = true}, -- TODO: Test if instance dialogue is blocked
    ["Constable Bolger"]    = {["Bree-land"] = true},
    ["Jim Skinner"]         = {["Bree-town"] = true},
    ["Drunken Reveller"]    = {["Bree-town"] = true},
}

function Say:isAllowed(message)
    -- message = "<Select:IID:0x034600005A656CD6>Waitress<\Select> says, 
    local id, name = message:match("^<Select:IID:(0x%x+)>(.-)</Select>")
    -- FIXME: id and name are null after assignment
    -- The game does not use double quotes ", only two single quotes ''
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
    local blockedLocations = self._Blocklist[name]
    if not blockedLocations then
        return true
    elseif Location:isUnknown() then
        return false
    elseif Location:isInstanced() then
        return true
    else
        return not blockedLocations[Location:getCurrent()]
    end
end

function Say:isFromLocalPlayer(message)
    return message:sub(1, 8) == "You say,"
end

function Say:isFromNpc(id)
    -- "0x0346"
    return id:sub(1, 11) == "0x034600005"
end

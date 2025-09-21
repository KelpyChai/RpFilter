import "Dandiron.RpFilter.Location"
import "Dandiron.RpFilter.TextUtils"

Say = {}

local BLOCKED_NPCS = {
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

local function isFromLocalPlayer(message)
    return message:sub(1, 4) == "You "
end

local function isFromNpc(id)
    return id:sub(1, 6) == "0x0346"
end

local function isNpcAllowed(name)
    local currBlockedNpcs = BLOCKED_NPCS[Location.getCurrent()]
    return not currBlockedNpcs or not currBlockedNpcs[name]
end

---Filters NPC chatter from the say channel
---@param message any
---@return boolean
function Say.isAllowed(message)
    local id, name = message:match("^<Select:IID:(0x%x-)>(.-)<\\Select>")

    if not id then
        return isFromLocalPlayer(message)
    elseif isFromNpc(id) then
        return isNpcAllowed(name)
    else
        -- Must be from another player
        return true
    end
end

local function formatVerse(say)
    local TAB = "   "

    say = say:gsub("says, '(.-["..WORD_CHARS.."].-/.-["..WORD_CHARS.."].*)'", function (verse)
        verse = Strip(verse)
        verse = verse:gsub("%s?/%s?", "\n" .. TAB)
        verse = "says:\n" .. TAB .. verse
        return verse
    end)

    return say
end

function Say.format(say, color)
    say = ReplacePlayerName(say)
    say = formatVerse(say)
    say = ReplaceEmDash(say)
    say = AddRgb(say, color)
    return say
end

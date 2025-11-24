import "Dandiron.RpFilter.Location"
import "Dandiron.RpFilter.TextUtils"

Say = {}

local BLOCKED_NPCS = {
    ["Bree-land"] = {
        ["Townsperson"] = true,
        ["Woodcutter"] = true,
        ["Bounder"] = true,
        ["Watcher"] = true,
        ["Worker"] = true,
        ["Neighbour"] = true,
        ["Tom Bombadil"] = true,
        ["Lalia"] = true,
        ["Constable Bolger"] = true,
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
        ["Idalene"] = true,
    },

    ["Trollshaws"] = {
        ["Aegúrel"] = true,
    },
}

local function isFromLocalPlayer(say)
    -- Works for "You say" and "You shout"
    return say:sub(1, 4) == "You "
end

---@param say string
---@return string|nil name The name of the player or NPC, if any
---@return string|nil id The ID extracted from the message, if any
function Say.parse(say)
    local id, name = say:match("^<Select:IID:(0x%x-)>(.-)<\\Select>")
    return isFromLocalPlayer(say) and LOCAL_PLAYER_NAME or name, id
end

local function isFromNpc(id)
    return id and id:sub(1, 6) == "0x0346"
end

local function isFromPlayer(name, id)
    return name and not isFromNpc(id)
end

function Say.isFromPlayer(say)
    return isFromPlayer(Say.parse(say))
end

local function isNpcAllowed(name)
    if name == nil then return false end
    local blockedNpcs = BLOCKED_NPCS[Location.getCurrent()]
    return Location.isInstanced() or not blockedNpcs or not blockedNpcs[name]
end

---Filters NPC chatter from the say channel
function Say.isAllowed(say)
    local name, id = Say.parse(say)
    return isFromPlayer(name, id) or isNpcAllowed(name)
end

---Replaces 'You say/shout' with '<player> says/shouts'
---@param say string
---@return string
local function replacePlayerName(say)
    if say:sub(1, 7) == "You say" then
        return LOCAL_PLAYER_NAME .. " says" .. say:sub(8)
    elseif say:sub(1, 9) == "You shout" then
        return LOCAL_PLAYER_NAME .. " shouts" .. say:sub(10)
    else
        return say
    end
end

local function replaceEmoticon(pre, emoticon, post)
    local marker = emoticon == "o/" and "\1" or "\1\2"
    return pre .. marker .. post
end

local function replaceSlash(name, verb, verse)
    local TAB = "   "
    verse = TAB .. verse:gsub("%s?/%s?", "\n" .. TAB)
    return name .. " " .. verb .. ":\n" .. verse
end

local function formatVerse(say)

    local wereEmoticonsFound = false
    repeat
        local res, count = say:gsub("([^"..WORD_CLASS.."/])(o//?)([%s%p])", replaceEmoticon)
        say = res
        wereEmoticonsFound = wereEmoticonsFound or count ~= 0
    until count == 0

    local namePattern = say:sub(1, 1) == "<" and "^(<Select:IID:0x%x->.-<\\Select>)" or "^(%a+)%-?%d-"
    local versePattern = " (%l+), '(.-["..WORD_CLASS.."].-/.-["..WORD_CLASS.."].-/.-["..WORD_CLASS.."].-/.-["..WORD_CLASS.."].*)'$"
    say = say:gsub(namePattern .. versePattern, replaceSlash)

    if wereEmoticonsFound then
        say = say:gsub("\1(\2?)", function (slash) return #slash == 0 and "o/" or "o//" end)
    end
    return say
end

local function format(say)
    return ComposeFuncs(say, Strip, replacePlayerName, formatVerse, ReplaceEmDash)
end

function Say.format(say, color)
    return AddRgb(format(say), color)
end

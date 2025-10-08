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
    return message:sub(1, 7) == "You say"
end

---Replaces 'You say' with '<player> says'
---@param say string
---@return string
local function replacePlayerName(say)
    return isFromLocalPlayer(say) and LOCAL_PLAYER_NAME.." says"..say:sub(8) or say
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

local function replaceEmoticon(pre, emoticon, post)
    local marker = emoticon == "o/" and "\1" or "\1\2"
    return pre .. marker .. post
end

local function replaceSlash(name, verse)
    local TAB = "   "
    verse = verse:gsub("%s?/%s?", "\n" .. TAB)
    return name .. " says:\n" .. TAB .. verse
end

local function formatVerse(say)

    local wereEmoticonsFound = false
    repeat
        local res, count = say:gsub("([^"..WORD_CHARS.."/])(o//?)([%s%p])", replaceEmoticon)
        say = res
        wereEmoticonsFound = wereEmoticonsFound or count ~= 0
    until count == 0

    local namePattern = say:sub(1, 1) == "<" and "^(<Select:IID:0x%x->.-<\\Select>)" or "^(%a+)%-?%d-"
    local versePattern = " says, '(.-["..WORD_CHARS.."].-/.-["..WORD_CHARS.."].-/.-["..WORD_CHARS.."].-/.-["..WORD_CHARS.."].*)'$"
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

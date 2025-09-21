import "Turbine.Gameplay"

import "Dandiron.RpFilter.Contraction"
import "Dandiron.RpFilter.TextUtils"

Emote = {}

-- Placeholder for "'"
local QUOTE_CHAR = "\1"
-- Placeholder for " '"
local OPENING_CHAR = "\2"
-- Placeholder for "' "
local CLOSING_CHAR = "\3"

local currEmoter
local isColorLight

local function getLighterOrDarker(playerName, settings)
    if playerName == "You" then
        playerName = GetPlayerName()
    end

    if playerName ~= currEmoter then
        currEmoter = playerName
        isColorLight = not isColorLight
    end

    return isColorLight and settings.lighter or settings.darker
end

local function formatHead(emote)
    local name, action = emote:match("^(%a+)%-?%d- (.+)")
    local firstChar = action:sub(1, 1)

    if firstChar == "|" or firstChar == "/" or firstChar == "\\" then
        emote = action:gsub("^"..firstChar.."+%s?", "")
    elseif action:sub(1, 3) == "'s " then
        local possessive = name:sub(-1) == "s" and "' " or "'s "
        emote = name .. possessive .. action:sub(4)
    elseif action:find("^l+ ") then
        emote = action:match("^l+ (.+)")
    end

    return emote, name
end

-- TODO: Handle verse between single quotes and
-- exclude slashes between single words (e.g. "AC/DC", "It's not either/or")
-- Might need .split("/") functionality?
local function formatVerse(emote, settings)
    if emote:find('".-/.-"') then return emote end

    local TAB = "   "

    emote = emote:gsub('%s*(\'*)("+)([^"/]*/[^"]*)("+)(\'*)%s*', function (before, opening, verse, closing, after)
        verse = Strip(verse)
        verse = verse:gsub("%s*/%s*", "\n" .. TAB)
        opening = "\n" .. OPENING_CHAR .. TAB .. before .. opening:sub(2)
        closing = closing:sub(1, -2) .. after .. CLOSING_CHAR .. "\n"
        return opening .. verse .. closing
    end)

    emote = Strip(emote)

    emote = emote:gsub(OPENING_CHAR.."(.-)"..CLOSING_CHAR, function (verse)
        if settings.isDialogueColored then
            verse = AddRgb(verse, settings.sayColor)
        end
        return verse
    end)

    return emote
end

function Emote.colorDialogue(emote, settings)
    local sayColor = settings.sayColor

    -- Colour text between "double quotes"
    emote = emote:gsub('"(%s*[^%s"][^"]*)("?)', function (dialogue, closing)
        dialogue = Strip(dialogue)
        -- Replace all apostrophes with placeholders
        dialogue = dialogue:gsub("'", QUOTE_CHAR)
        dialogue = AddRgb('"' .. dialogue .. closing, sayColor)
        return dialogue
    end)

    -- TODO: Handle words with internal and leading apostrophes (e.g. 'tisn't, 'twouldn't, 'tain't)

    -- Replace apostrophes within words with placeholders (e.g. it's, can't, Bob's, rock'n'roll)
    repeat
        local res, count = emote:gsub("(["..WORD_CHARS.."]+)'(["..WORD_CHARS.."]+)", "%1"..QUOTE_CHAR.."%2")
        emote = res
    until count == 0

    if emote:find("'", 1, true) then
        -- Replace leading apostrophe with placeholder if word is valid contraction (e.g. 'tis, 'ello, 'fraid)
        emote = emote:gsub("('?)('["..WORD_CHARS.."]+)", function (speechMark, word)
            if Contraction:isValidHeadless(speechMark, word) then
                word = QUOTE_CHAR .. word:sub(2)
            end
            return speechMark .. word
        end)

        -- Replace trailing apostrophe with placeholder if word is valid contraction (e.g. Marius', ol', walkin')
        emote = emote:gsub("(["..WORD_CHARS.."]+')(%p*)", function (word, punctuation)
            if Contraction:isValidTailless(word, punctuation) then
                word = word:sub(1, -2) .. QUOTE_CHAR
            end
            return word .. punctuation
        end)

        -- Colour text between remaining 'single quotes'
        emote = " " .. emote:gsub("'([%.%?,!%-%+]*) '", CLOSING_CHAR.."%1"..OPENING_CHAR):gsub("' ([%-%+])", "'  %1") .. " "
        emote = emote:gsub(" '", OPENING_CHAR):gsub("'([%.%?,!%-%+]*) ", CLOSING_CHAR.."%1")

        emote = emote:gsub(OPENING_CHAR.."(%s*[^%s"..OPENING_CHAR.."][^"..OPENING_CHAR.."]*)"..CLOSING_CHAR.."([%.%?,!%-%+]*)", function (dialogue, punctuation)
            dialogue = Strip(dialogue)
            return " "..AddRgb("'"..dialogue.."'", sayColor)..punctuation.." "
        end)

        emote = emote:gsub(OPENING_CHAR.."([%s%p]*["..WORD_CHARS.."][^"..CLOSING_CHAR.."%+]*)(%+?) $", function (dialogue, plus)
            dialogue = Strip(dialogue)
            if plus == "+" then
                plus = " +"
            end
            return " "..AddRgb("'"..dialogue, sayColor)..plus.." "
        end)

        emote = emote:gsub(CLOSING_CHAR.."([%.%?,!%-%+]*)", "'%1 "):gsub(OPENING_CHAR, " '"):sub(2, -2):gsub("'</rgb>([%.%?,!%-%+]*)  <rgb=(.-)>'", "'</rgb>%1 <rgb=%2>'"):gsub("'</rgb>  ([%-%+])", "'</rgb> %1")
    end

    emote = emote:gsub(QUOTE_CHAR, "'")
    return emote
end

local function addEmoteColor(emote, name, settings)
    if settings.areEmotesContrasted then
        emote = AddRgb(emote, getLighterOrDarker(name, settings))
    else
        emote = AddRgb(emote, settings.emoteColor)
    end

    return emote
end

---Formats emotes according to given settings
---@param emote string text whose whitespace is trimmed and normalized
---@return string
function Emote:format(emote, settings)
    local name

    emote, name = formatHead(emote)
    emote = formatVerse(emote, settings)
    if settings.isEmphasisUnderlined then emote = UnderlineAsterisks(emote) end
    if settings.isDialogueColored then emote = self.colorDialogue(emote, settings) end
    -- Em dashes are not ASCII characters, they will confuse match() and gsub()
    emote = ReplaceEmDash(emote)
    emote = addEmoteColor(emote, name, settings)

    return emote
end

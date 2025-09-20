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

---Formats messages from the emote channel, including multi-post emotes
---@param emote string text whose whitespace is trimmed and normalized
---@return string
function Emote:format(emote, settings)
    local name
    -- Order of functions matters, do not change without testing
    emote, name = formatHead(emote)

    -- TODO: Handle verse between single quotes and
    -- exclude slashes between single words (e.g. "AC/DC", "It's not either/or")
    -- Might need .split("/") functionality?
    if emote:find('".-/.-"') then
        emote = emote:gsub('%s*(\'*)("+)([^"/]*/[^"]*)("+)(\'*)%s*', function (before, opening, verse, closing, after)
            verse = Strip(verse)
            verse = verse:gsub("%s*/%s*", "\n   ")
            opening = "\n" .. OPENING_CHAR .. "   " .. before .. opening:sub(2)
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
    end

    emote = UnderlineAsterisks(emote)

    if settings.isDialogueColored then
        -- Colour text between "quotation marks"
        emote = emote:gsub('"(%s*[^%s"][^"]*)("?)', function (dialogue, closing)
            -- Strip whitespace, replace apostrophes between "quotation marks"
            dialogue = Strip(dialogue)
            dialogue = dialogue:gsub("'", QUOTE_CHAR)
            return AddRgb('"' .. dialogue .. closing, settings.sayColor)
        end)

        -- TODO: Replace words with internal and leading apostrophes ('tisn't, 'twouldn't, 'tain't)

        -- Replace internal apostrophes
        repeat
            local res, count = emote:gsub("(["..WORD_CHARS.."]+'["..WORD_CHARS.."]+)", function (word)
                return word:gsub("'", QUOTE_CHAR)
            end)
            emote = res
        until count == 0

        if emote:find("'", 1, true) then
            -- If word with leading apostrophe is valid, replace the apostrophe
            emote = emote:gsub("('?)('["..WORD_CHARS.."]+)", function (speechMark, word)
                if Contraction:isValidHeadless(speechMark, word) then
                    word = QUOTE_CHAR .. word:sub(2)
                end
                return speechMark .. word
            end)

            -- If word with trailing apostrophe is valid, replace the apostrophe
            emote = emote:gsub("(["..WORD_CHARS.."]+')(%p*)", function (word, punctuation)
                if Contraction:isValidTailless(word, punctuation) then
                    word = word:sub(1, -2) .. QUOTE_CHAR
                end
                return word .. punctuation
            end)

            -- Colour text between remaining 'speech marks'
            emote = " " .. emote:gsub("'([%.%?,!%-%+]*) '", CLOSING_CHAR.."%1"..OPENING_CHAR):gsub("' ([%-%+])", "'  %1") .. " "
            emote = emote:gsub(" '", OPENING_CHAR):gsub("'([%.%?,!%-%+]*) ", CLOSING_CHAR.."%1")

            emote = emote:gsub(OPENING_CHAR.."(%s*[^%s"..OPENING_CHAR.."][^"..OPENING_CHAR.."]*)"..CLOSING_CHAR.."([%.%?,!%-%+]*)", function (dialogue, punctuation)
                dialogue = Strip(dialogue)
                return " "..AddRgb("'"..dialogue.."'", settings.sayColor)..punctuation.." "
            end)

            emote = emote:gsub(OPENING_CHAR.."([%s%p]*["..WORD_CHARS.."][^"..CLOSING_CHAR.."%+]*)(%+?) $", function (dialogue, plus)
                dialogue = Strip(dialogue)
                if plus == "+" then
                    plus = " +"
                end
                return " "..AddRgb("'"..dialogue, settings.sayColor)..plus.." "
            end)

            emote = emote:gsub(CLOSING_CHAR.."([%.%?,!%-%+]*)", "'%1 "):gsub(OPENING_CHAR, " '"):sub(2, -2):gsub("'</rgb>([%.%?,!%-%+]*)  <rgb=(.-)>'", "'</rgb>%1 <rgb=%2>'"):gsub("'</rgb>  ([%-%+])", "'</rgb> %1")
        end

        emote = emote:gsub(QUOTE_CHAR, "'")
    end

    emote = ReplaceEmDash(emote)

    if settings.areEmotesContrasted then
        emote = AddRgb(emote, getLighterOrDarker(name, settings))
    else
        emote = AddRgb(emote, settings.emoteColor)
    end

    return emote
end

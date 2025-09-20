import "Turbine.Gameplay"

import "Dandiron.RpFilter.Contraction"
import "Dandiron.RpFilter.TextUtils"

Emote = {}

-- Placeholder for "'"
local apostropheTemp = "\1"
-- Placeholder for " '"
local quoteTemp = "\2"
-- Placeholder for "' "
local unquoteTemp = "\3"

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
            verse = verse:match("^%s*(.-)%s*$"):gsub("%s*/%s*", "\n   ")
            opening = "\n" .. quoteTemp .. "   " .. before .. opening:sub(2)
            closing = closing:sub(1, -2) .. after .. unquoteTemp .. "\n"
            return opening .. verse .. closing
        end)

        emote = emote:match("^%s*(.-)%s*$")
        emote = emote:gsub(quoteTemp.."(.-)"..unquoteTemp, function (verse)
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
            dialogue = dialogue:match("^%s*(.-)%s*$"):gsub("'", apostropheTemp)
            return AddRgb('"' .. dialogue .. closing, settings.sayColor)
        end)

        -- TODO: Replace words with internal and leading apostrophes ('tisn't, 'twouldn't, 'tain't)

        -- Replace internal apostrophes
        repeat
            local res, count = emote:gsub("(["..WordChars.."]+'["..WordChars.."]+)", function (word)
                return word:gsub("'", apostropheTemp)
            end)
            emote = res
        until count == 0

        if emote:find("'", 1, true) then
            -- If word with leading apostrophe is valid, replace the apostrophe
            emote = emote:gsub("('?)('["..WordChars.."]+)", function (speechMark, word)
                if Contraction:isValidHeadless(speechMark, word) then
                    word = apostropheTemp .. word:sub(2)
                end
                return speechMark .. word
            end)

            -- If word with trailing apostrophe is valid, replace the apostrophe
            emote = emote:gsub("(["..WordChars.."]+')(%p*)", function (word, punctuation)
                if Contraction:isValidTailless(word, punctuation) then
                    word = word:sub(1, -2) .. apostropheTemp
                end
                return word .. punctuation
            end)

            -- Colour text between remaining 'speech marks'
            emote = " " .. emote:gsub("'([%.%?,!%-%+]*) '", unquoteTemp.."%1"..quoteTemp):gsub("' ([%-%+])", "'  %1") .. " "
            emote = emote:gsub(" '", quoteTemp):gsub("'([%.%?,!%-%+]*) ", unquoteTemp.."%1")

            emote = emote:gsub(quoteTemp.."(%s*[^%s"..quoteTemp.."][^"..quoteTemp.."]*)"..unquoteTemp.."([%.%?,!%-%+]*)", function (dialogue, punctuation)
                dialogue = dialogue:match("^%s*(.-)%s*$")
                return " "..AddRgb("'"..dialogue.."'", settings.sayColor)..punctuation.." "
            end)

            emote = emote:gsub(quoteTemp.."([%s%p]*["..WordChars.."][^"..unquoteTemp.."%+]*)(%+?) $", function (dialogue, plus)
                dialogue = dialogue:match("^%s*(.-)%s*$")
                if plus == "+" then
                    plus = " +"
                end
                return " "..AddRgb("'"..dialogue, settings.sayColor)..plus.." "
            end)

            emote = emote:gsub(unquoteTemp.."([%.%?,!%-%+]*)", "'%1 "):gsub(quoteTemp, " '"):sub(2, -2):gsub("'</rgb>([%.%?,!%-%+]*)  <rgb=(.-)>'", "'</rgb>%1 <rgb=%2>'"):gsub("'</rgb>  ([%-%+])", "'</rgb> %1")
        end

        emote = emote:gsub(apostropheTemp, "'")
    end

    emote = ReplaceEmDash(emote)

    if settings.areEmotesContrasted then
        emote = AddRgb(emote, getLighterOrDarker(name, settings))
    else
        emote = AddRgb(emote, settings.emoteColor)
    end

    return emote
end

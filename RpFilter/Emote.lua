import "Turbine.Gameplay"

import "Dandiron.RpFilter.Contraction"
import "Dandiron.RpFilter.TextUtils"

Emote = {
    -- multiPosts = {}
}

-- Placeholder for "'"
local apostropheTemp = "\1"
-- Placeholder for " '"
local quoteTemp = "\2"
-- Placeholder for "' "
local unquoteTemp = "\3"

function Emote:getLightOrDark(settings)
    return self.isCurrColorLight and settings.lighter or settings.darker
end

---Formats messages from the emote channel, including multi-post emotes
---@param emote string
---@return string
function Emote:format(emote, settings)
    local name, action = emote:match("^(%a+)%-?%d- (.+)")

    -- TODO: Handle these cases

    -- /e "Lua is an extension programming language designed to support general procedural programming with data description facilities."
    -- /e | "You know," she mutters, "I was just thinking of that."

    -- /e <very long post> +
    -- /e <even more>

    -- /e "Blah blah blah +"
    -- /e "I'm not done speaking yet!"

    local firstChar = action:sub(1, 1)
    if action:sub(1, 3) == "'s " then
        emote = name .. "'s " .. action:gsub("^'s%s+", "")
    elseif firstChar == "|" then
        emote = action:gsub("^|+%s*", "")
    elseif firstChar == "/" then
        emote = action:gsub("^/+%s*", "")
    elseif firstChar == "\\" then
        emote = action:gsub("^\\+%s*", "")
    -- elseif action:sub(1, 1) == "+" then
    --     emote = action:gsub("^%+%s*", "")
    elseif action:match("^l+ ") then
        emote = action:gsub("^l+%s+", "")
    end

    -- TODO: Handle verse between single quotes and
    -- exclude slashes between single words (e.g. "AC/DC", "It's not either/or")
    -- Might need .split("/") functionality?
    if action:find('".-/.-"') then
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

        if action:sub(1, 3) == "'s " and action:sub(4):find("'") or action:find("'") then
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

    if settings.areEmotesContrasted then
        local myName = Turbine.Gameplay.LocalPlayer:GetInstance():GetName()
        if name == Emote.currEmoter or
          (name == "You" and Emote.currEmoter == myName) or
          (name == myName and Emote.currEmoter == "You") then
            emote = AddRgb(emote, self:getLightOrDark())
        else
            Emote.currEmoter = name
            Emote.isCurrColorLight = not Emote.isCurrColorLight
            emote = AddRgb(emote, self:getLightOrDark())
        end
    end

    emote = UnderlineAsterisks(emote)
    emote = ReplaceEmDash(emote)
    emote = AddRgb(emote, settings.emoteColor)

    return emote
end

    -- Optional features:
    -- Highlight player names and/or make them inspectable
    -- Line break between each post, or between different characters

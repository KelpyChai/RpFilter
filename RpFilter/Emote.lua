import "Turbine.Gameplay"

import "Dandiron.RpFilter.Settings"
import "Dandiron.RpFilter.Contraction"
import "Dandiron.RpFilter.TextUtils"

Emote = {
    -- multiPosts = {}
}

local zeroWidthSpace = string.char(0xE2, 0x80, 0x8B)

if Settings.options.areEmotesContrasted then
    Emote.isCurrColorLight = false
end

function Emote:getLightOrDark()
    if self.isCurrColorLight then
        return Settings:getLighterColor()
    else
        return Settings:getDarkerColor()
    end
end

---Formats messages from the emote channel, including multi-post emotes
---@param emote string
---@return string
function Emote:format(emote)
    local name, action = emote:match("^(%a+)%-?%d- (.+)")

    -- TODO: Handle these cases

    -- Starting with words like 'tis and 'cause and '90s
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

    emote = UnderlineAsterisks(emote)

    if Settings.options.isDialogueColored then
        -- Colour text between "quotation marks"
        emote = emote:gsub('"([^"]+)("?)', function (dialogue, closing)
            -- Strip whitespace, replace apostrophes between "quotation marks"
            dialogue = dialogue:match("^%s*(.-)%s*$"):gsub("'", zeroWidthSpace)
            return AddRgb('"' .. dialogue .. closing, Settings:getSayColor())
        end)

        -- Replace internal apostrophes
        repeat
            local res, count = emote:gsub("([^%s%p]+'[^%s%p]+)", function (word)
                return word:gsub("'", zeroWidthSpace)
            end)
            emote = res
        until count == 0

        if action:sub(2):find("'") then
            -- If word with leading apostrophe is invalid, replace the apostrophe
            emote = emote:gsub("('?)('["..WordChars.."]+)", function (speechMark, word)
                if Contraction:isValidHeadless(speechMark, word) then
                    word = zeroWidthSpace .. word:sub(2)
                end
                return speechMark .. word
            end)

            -- If word with trailing apostrophe is invalid, replace the apostrophe
            emote = emote:gsub("(["..WordChars.."]+')", function (word)
                if Contraction:isValidTailless(word) then
                    word = word:sub(1, -2) .. zeroWidthSpace
                end
                return word
            end)

            -- TODO: Explicitly catch words like 'tisn't instead of colouring two quotation marks
            -- Colour text between remaining 'speech marks'
            emote = emote:gsub("(''?)([^']+)('?)", function (opening, dialogue, closing)
                dialogue = dialogue:match("^%s*(.-)%s*$")
                return AddRgb(opening..dialogue..closing, Settings:getSayColor())
            end)
        end

        emote = emote:gsub(zeroWidthSpace, "'")
    end

    if Settings.options.areEmotesContrasted then
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

    return emote
end

    -- Optional features:
    -- Highlight player names and/or make them inspectable
    -- Line break between each post, or between different characters
    -- /clear

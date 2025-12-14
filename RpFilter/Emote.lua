import "Dandiron.RpFilter.Contraction"
import "Dandiron.RpFilter.TextUtils"
import "Dandiron.RpFilter.EmoteColor"

Emote = {}

local multiDialogue = {}

do
    local localWords = {You=true, Nope=true, Burp=true, Who=true, Oops=true, It=true}
    function Emote.parseName(emote)
        local name = emote:match("^%a+")
        return localWords[name] and LOCAL_PLAYER_NAME or name
    end
end

local function formatHead(emote)
    local name, possessive, action = emote:match("^(%a+)%-?%d-('?s?) (.+)")
    if not action then return emote end
    local delimiterEnd = select(2, action:find("^[|/\\]+%s?")) or select(2, action:find("^l+ "))

    if delimiterEnd then
        return action:sub(delimiterEnd + 1)
    elseif action:sub(1, 3) == "'s " then
        possessive = name:sub(-1) == "s" and "'" or "'s"
        action = action:sub(4)
    elseif action:sub(1, 1) == "," then
        name = name .. ","
        action = Strip(action:sub(2))
    end
    return name .. possessive .. " " .. action
end

function Emote.colorDialogue(emote, name, sayColor)
    -- Placeholder for mid-word apostrophe, e.g. "'"
    local QUOTE_CHAR = "\1"
    -- Placeholder for opening quotation mark, e.g. " '"
    local OPENING = "\2"
    -- Placeholder for closing quotation mark, e.g. "' "
    local CLOSING = "\3"
    -- Placeholder for unknown quotation mark
    local UNKNOWN = "\4"

    local wasMultiPost = false

    local firstSpeechMark = multiDialogue[name]
    if firstSpeechMark and emote:sub(1, #name + 1) ~= name.."'" then
        local isNameIncluded = false

        if emote:sub(1, #name) == name then
            -- Skips space after name
            emote = emote:sub(#name + 2)
            isNameIncluded = true
        end

        emote = emote:gsub("^([%-%+])%s?(['\"])", "%1 %2")
        if not isNameIncluded or emote:find("^[%-%+]%s?[^'\"]") then
            emote = firstSpeechMark .. emote
            wasMultiPost = true
        end

        if isNameIncluded and not wasMultiPost then emote = name .. " " .. emote end
    end

    local isMultiPost = false

    local lastSpeechMark = emote:match("[%-%+]%s?(['\"])$")
    if lastSpeechMark then
        multiDialogue[name] = lastSpeechMark
        isMultiPost = true
    end

    -- Colour text between "double quotes"
    emote = emote
        :gsub("“", '"')
        :gsub("”", '"')
        :gsub('"(%s?[^%s"][^"]*)("?)', function (dialogue, closing)
            dialogue = Strip(dialogue)

            if closing == "" and (dialogue:sub(-1) == "-" or dialogue:sub(-1) == "+") then
                multiDialogue[name] = '"'
                isMultiPost = true
            end

            -- Replace all apostrophes with placeholders
            dialogue = dialogue:gsub("'", QUOTE_CHAR):gsub("‘", QUOTE_CHAR):gsub("’", QUOTE_CHAR)
            dialogue = AddRgb('"' .. dialogue .. closing, sayColor)
            return dialogue
        end)

    -- TODO: Handle words with internal and leading apostrophes (e.g. 'tisn't, 'twouldn't, 'tain't)

    -- Replace apostrophes within words with placeholders (e.g. it's, can't, Bob's, rock'n'roll)
    repeat
        local res, count = emote:gsub("(["..WORD_CLASS.."]+)'(["..WORD_CLASS.."]+)", "%1"..QUOTE_CHAR.."%2")
        emote = res
    until count == 0

    repeat
        local res, count = emote:gsub("(["..WORD_CLASS.."]+)’(["..WORD_CLASS.."]+)", "%1"..QUOTE_CHAR.."%2")
        emote = res
    until count == 0

    if emote:find("'", 1, true) or emote:find("‘", 1, true) or emote:find("’", 1, true) then
        -- Replace trailing apostrophe with placeholder if word is valid contraction (e.g. Marius', ol', walkin')
        local function replaceTrailing(word, punctuation)
            local isValidTailless = Contraction.isValidTailless(word.."'", punctuation)
            return word .. (isValidTailless and QUOTE_CHAR or "'") .. punctuation
        end

        emote = emote
            :gsub("(["..WORD_CLASS.."]+)'(%p*)", replaceTrailing)
            :gsub("(["..WORD_CLASS.."]+)’(%p*)", replaceTrailing)

        -- Colour text between remaining 'single quotes'

        -- Pads string with space so quotes can match
        if emote:sub(1, 1) == "'" or emote:sub(1, 3) == "‘" then emote = " " .. emote end
        if emote:sub(-1) == "'" or emote:sub(-3, -1) == "’" then emote = emote .. " " end

        emote = emote
            :gsub("‘", OPENING)
            :gsub("’", "'")
            -- Matches + after dialogue at the end of the emote, e.g. 'Did you know'+
            :gsub("'(%s?[%-%+])$", CLOSING.."%1")
            -- Replace closing and opening quotes of neighbouring dialogue with placeholders
            :gsub("'([%s%.%?,!]+)'", function (wordBoundary)
                if wordBoundary:find("^%.%.%.+$") then
                    return OPENING..wordBoundary..CLOSING
                else
                    return CLOSING..wordBoundary..OPENING
                end
            end)
            -- Replace closing quotes with placeholders
            :gsub("'([%s%.%?,!%-]+)", function (wordBoundary)
                if wordBoundary:sub(1, 3) == '...' or wordBoundary:sub(1, 1) == '-' then
                    return OPENING..wordBoundary
                else
                    return CLOSING..wordBoundary
                end
            end)
            -- Replace opening quotes with placeholders
            :gsub(" '", " "..OPENING)
            :gsub("([%.%?,!%-~]+)'(%s?)", function (wordBoundary, space)
                if space == " " or wordBoundary:sub(1, 3) == '...' or wordBoundary:sub(1, 1) == '-' or wordBoundary:sub(-1) == "~" then
                    return wordBoundary..CLOSING..space
                else
                    return wordBoundary..UNKNOWN
                end
            end)
            :gsub("("..CLOSING.."[^"..CLOSING..OPENING.."\4]-)\4([^"..CLOSING..OPENING.."\4]-"..CLOSING..")", "%1"..OPENING.."%2")
            :gsub("^([^"..CLOSING..OPENING.."\4]-)\4([^"..CLOSING..OPENING.."\4]-"..CLOSING..")", "%1"..OPENING.."%2")
            :gsub(UNKNOWN, CLOSING)

        -- Matches text between opening and closing quote, ensuring it is non-whitespace and contains no opening quotes
        emote = emote:gsub(OPENING.."('*%?*[^'%s"..CLOSING.."][^"..CLOSING.."]*)"..CLOSING, function (dialogue)
            dialogue = Strip(dialogue)
            dialogue = dialogue:gsub("["..OPENING..CLOSING.."]", "'")
            dialogue = AddRgb("'"..dialogue.."'", sayColor)
            return dialogue
        end)

        -- Matches final unbounded single quoted dialogue, if there is one
        emote = emote:gsub(OPENING.."('*%?*[^%s"..CLOSING.."][^"..CLOSING.."]*)$", function (dialogue)
            dialogue = Strip(dialogue)

            if dialogue:sub(-1) == "-" or dialogue:sub(-1) == "+" then
                multiDialogue[name] = "'"
                isMultiPost = true
            end

            dialogue = dialogue:gsub("["..OPENING..CLOSING.."]", "'")
            dialogue = AddRgb("'"..dialogue, sayColor)
            return dialogue
        end)

        emote = emote:gsub("["..OPENING..CLOSING.."]", "'")
        emote = Strip(emote)
    end

    emote = emote:gsub(QUOTE_CHAR, "'")

    -- TODO: Consider order of operations
    if not isMultiPost then multiDialogue[name] = nil end
    if wasMultiPost then emote = emote:gsub(firstSpeechMark, "", 1) end

    return emote
end

---@param emote string
---@return string
function Emote.formatText(emote, name, sayColor, opts)
    local isUnderlined, isColored = opts.isEmphasisUnderlined, opts.isDialogueColored
    return ComposeFuncs(emote,
        Strip,
        formatHead,
        function (text) return isUnderlined and UnderlineAsterisks(text) or text end,
        function (text) return isColored and Emote.colorDialogue(text, name, sayColor) or text end,
        -- formatVerse
        ReplaceEmDash
    )
end

---@param emote string
---@param emoteColor table
---@param sayColor table
---@param options table
---@return string
function Emote.format(emote, emoteColor, sayColor, options)
    local name = Emote.parseName(emote)
    local formatted = Emote.formatText(emote, name, sayColor, options)
    emoteColor = EmoteColor.update(name, emoteColor, options)
    return AddRgb(formatted, emoteColor)
end

function Emote.updatePlayer(name)
    multiDialogue[name] = nil
end

import "Dandiron.RpFilter.Contraction"
import "Dandiron.RpFilter.TextUtils"
import "Dandiron.RpFilter.EmoteColor"

Emote = {}

local multiPosts = {}

local function parseName(emote)
    local name = emote:match("^%a+")
    return name == "You" and LOCAL_PLAYER_NAME or name
end

local function formatHead(emote)
    local name, possessive, action = emote:match("^(%a+)%-?%d-('?s?) (.+)")
    local delimiterEnd = ({action:find("^[|/\\]+%s?")})[2] or ({action:find("^l+ ")})[2]

    if delimiterEnd and (action:find(name, 1, true) or multiPosts[name]) then
        return action:sub(delimiterEnd + 1)
    elseif action:sub(1, 3) == "'s " then
        possessive = name:sub(-1) == "s" and "'" or "'s"
        action = action:sub(4)
    end
    return name .. possessive .. " " .. action
end

function Emote.colorDialogue(emote, name, sayColor)
    -- Placeholder for "'"
    local QUOTE_CHAR = "\1"
    -- Placeholder for opening quotation mark, e.g. " '"
    local OPENING = "\2"
    -- Placeholder for closing quotation mark, e.g. "' "
    local CLOSING = "\3"
    local UNKNOWN = "\4"

    local wasMultiPost = false
    local isNameIncluded = false

    local firstSpeechMark = multiPosts[name]
    if firstSpeechMark and emote:sub(1, #name + 1) ~= name.."'" then
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

        if isNameIncluded and not wasMultiPost then
            emote = name .. " " .. emote
            isNameIncluded = false
        end
    end

    local isMultiPost = false

    local lastSpeechMark = emote:match("(['\"])%s?[%-%+]$") or emote:match("[%-%+]%s?(['\"])$")
    if lastSpeechMark then
        multiPosts[name] = lastSpeechMark
        isMultiPost = true
    end

    -- Colour text between "double quotes"
    emote = emote:gsub('"(%s?[^%s"][^"]*)("?)', function (dialogue, closing)
        dialogue = Strip(dialogue)

        local lastChar = dialogue:sub(-1)
        if closing == "" and (lastChar == "-" or lastChar == "+") then
            multiPosts[name] = '"'
            isMultiPost = true
        end

        -- Replace all apostrophes with placeholders
        dialogue = dialogue:gsub("'", QUOTE_CHAR)
        dialogue = AddRgb('"' .. dialogue .. closing, sayColor)
        return dialogue
    end)

    -- TODO: Handle words with internal and leading apostrophes (e.g. 'tisn't, 'twouldn't, 'tain't)

    -- Replace apostrophes within words with placeholders (e.g. it's, can't, Bob's, rock'n'roll)
    repeat
        local res, count = emote:gsub("(["..WORD_CLASS.."]+)'(["..WORD_CLASS.."]+)", "%1"..QUOTE_CHAR.."%2")
        emote = res
    until count == 0

    if emote:find("'", 1, true) then
        -- Replace trailing apostrophe with placeholder if word is valid contraction (e.g. Marius', ol', walkin')
        emote = emote:gsub("(["..WORD_CLASS.."]+')(%p*)", function (word, punctuation)
            if Contraction.isValidTailless(word, punctuation) then
                word = word:sub(1, -2) .. QUOTE_CHAR
            end
            return word .. punctuation
        end)

        -- Colour text between remaining 'single quotes'

        -- Pads string with space so quotes can match
        if emote:sub(1, 1) == "'" then emote = " " .. emote end
        if emote:sub(-1) == "'" then emote = emote .. " " end

        emote = emote
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

            local lastChar = dialogue:sub(-1)
            if lastChar == "-" or lastChar == "+" then
                multiPosts[name] = "'"
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
    if not isMultiPost then multiPosts[name] = nil end
    if wasMultiPost then emote = emote:gsub(firstSpeechMark, "", 1) end
    if isNameIncluded then emote = name .. " " .. emote end

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
    local name = parseName(emote)
    local formatted = Emote.formatText(emote, name, sayColor, options)
    emoteColor = EmoteColor.update(name, emoteColor, options)
    return AddRgb(formatted, emoteColor)
end

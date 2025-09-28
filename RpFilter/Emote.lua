import "Dandiron.RpFilter.Contraction"
import "Dandiron.RpFilter.TextUtils"
import "Dandiron.RpFilter.EmoteColor"

Emote = {}

local function parseName(emote)
    local name = emote:match("^(%a+'?s?)%-?%d- ")
    if name == "You" then
        name = LOCAL_PLAYER_NAME
    elseif name:sub(-2) == "'s" then
        name = name:sub(1, -3)
    end
    return name
end

local function formatHead(emote)
    local name, action = emote:match("^(%a+'?s?)%-?%d- (.+)")
    local firstChar = action:sub(1, 1)

    if firstChar == "|" or firstChar == "/" or firstChar == "\\" then
        return action:gsub("^"..firstChar.."+%s?", "")
    elseif action:sub(1, 3) == "'s " then
        local possessive = name:sub(-1) == "s" and "' " or "'s "
        return name .. possessive .. action:sub(4)
    else
        local res = action:match("^l+ (.+)")
        return res or emote
    end
end

function Emote.colorDialogue(emote, sayColor)
    -- Placeholder for "'"
    local QUOTE_CHAR = "\1"
    -- Placeholder for " '"
    local OPENING_CHAR = "\2"
    -- Placeholder for "' "
    local CLOSING_CHAR = "\3"
    local UNKNOWN = "\4"

    -- Colour text between "double quotes"
    emote = emote:gsub('"(%s?[^%s"][^"]*)("?)', function (dialogue, closing)
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
        -- Replace trailing apostrophe with placeholder if word is valid contraction (e.g. Marius', ol', walkin')
        emote = emote:gsub("(["..WORD_CHARS.."]+')(%p*)", function (word, punctuation)
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
            :gsub("'%+", CLOSING_CHAR.."+")
            -- Replace closing and opening quotes of neighbouring dialogue with placeholders
            :gsub("'([%s%.%?,!]+)'", function (wordBoundary)
                if wordBoundary:match("^%.%.%.+$") then
                    return OPENING_CHAR..wordBoundary..CLOSING_CHAR
                else
                    return CLOSING_CHAR..wordBoundary..OPENING_CHAR
                end
            end)
            -- Replace closing quotes with placeholders
            :gsub("'([%s%.%?,!%-]+)", function (wordBoundary)
                if wordBoundary:sub(1, 3) == '...' or wordBoundary:sub(1, 1) == '-' then
                    return OPENING_CHAR..wordBoundary
                else
                    return CLOSING_CHAR..wordBoundary
                end
            end)
            -- Replace opening quotes with placeholders
            :gsub(" '", " "..OPENING_CHAR)
            :gsub("([%.%?,!%-~]+)'(%s?)", function (wordBoundary, space)
                if space == " " or wordBoundary:sub(1, 3) == '...' or wordBoundary:sub(1, 1) == '-' or wordBoundary:sub(-1) == "~" then
                    return wordBoundary..CLOSING_CHAR..space
                else
                    return wordBoundary..UNKNOWN
                end
            end)
            :gsub("("..CLOSING_CHAR.."[^"..CLOSING_CHAR..OPENING_CHAR.."\4]-)\4([^"..CLOSING_CHAR..OPENING_CHAR.."\4]-"..CLOSING_CHAR..")", "%1"..OPENING_CHAR.."%2")
            :gsub("^([^"..CLOSING_CHAR..OPENING_CHAR.."\4]-)\4([^"..CLOSING_CHAR..OPENING_CHAR.."\4]-"..CLOSING_CHAR..")", "%1"..OPENING_CHAR.."%2")
            :gsub(UNKNOWN, CLOSING_CHAR)

        -- Matches text between opening and closing quote, ensuring it is non-whitespace and contains no opening quotes
        emote = emote:gsub(OPENING_CHAR.."('*%?*[^'%s"..CLOSING_CHAR.."][^"..CLOSING_CHAR.."]*)"..CLOSING_CHAR, function (dialogue)
            dialogue = Strip(dialogue)
            dialogue = dialogue:gsub("["..OPENING_CHAR..CLOSING_CHAR.."]", "'")
            dialogue = AddRgb("'"..dialogue.."'", sayColor)
            return dialogue
        end)

        -- Matches final unbounded single quoted dialogue, if there is one
        emote = emote:gsub(OPENING_CHAR.."('*%?*[^%s"..CLOSING_CHAR.."][^"..CLOSING_CHAR.."]*)$", function (dialogue)
            dialogue = Strip(dialogue)
            dialogue = dialogue:gsub("["..OPENING_CHAR..CLOSING_CHAR.."]", "'")
            dialogue = AddRgb("'"..dialogue, sayColor)
            return dialogue
        end)

        emote = emote:gsub("["..OPENING_CHAR..CLOSING_CHAR.."]", "'")
        emote = Strip(emote)
    end

    emote = emote:gsub(QUOTE_CHAR, "'")
    return emote
end

---@param emote string
---@return string
function Emote.formatText(emote, sayColor, opts)
    local isUnderlined, isColored = opts.isEmphasisUnderlined, opts.isDialogueColored
    return ComposeFuncs(emote,
        Strip,
        formatHead,
        function (text) return isUnderlined and UnderlineAsterisks(text) or text end,
        function (text) return isColored and Emote.colorDialogue(text, sayColor) or text end,
        -- formatVerse
        ReplaceEmDash
    )
end

local function addColor(emote, name, emoteColor, options)
    EmoteColor.update(name, emoteColor, options)
    return AddRgb(emote, EmoteColor.get(name, emoteColor, options))
end

---@param emote string
---@param emoteColor table
---@param sayColor table
---@param options table
---@return string
function Emote.format(emote, emoteColor, sayColor, options)
    local formatted = Emote.formatText(emote, sayColor, options)
    local name = parseName(emote)
    return addColor(formatted, name, emoteColor, options)
end

import "Dandiron.RpFilter.Wordlist"

Contraction = {}

---Returns true for '...potatoes'', '...potatoes'.', '...potatoes',' but not '...potatoes'
---@param punctuation string
---@return boolean
local function isEndOfDialogue(punctuation)
    if punctuation:len() == 0 then
        return false
    end

    if punctuation:find("[%.%?%-,!~]*'") then
        return true
    end

    return false
end

local TAILLESS_WORDS = {
    ["ain'"] = true,
    ["an'"] = true,
    ["didn'"] = true,
    ["doan'"] = true,
    ["fo'"] = true,
    ["gon'"] = true,
    ["mo'"] = true,
    ["o'"] = true,
    ["ol'"] = true,
    ["po'"] = true,
}

---@param word string word ending with apostrophe, e.g. knowin', countries'
---@param punctuation string apostrophe preceding the word
---@return boolean
function Contraction.isValidTailless(word, punctuation)
    local lowercase = word:lower()
    local body = lowercase:sub(1, -2)

    if TAILLESS_WORDS[lowercase] then
        return true
    elseif word:sub(-2) == "s'" then
        local root = body:sub(1, -2)
        if (IsCapitalized(word) and not Wordlist.isValidWord(body)) or Wordlist.NOUNS[word:sub(1, -2)] or Wordlist.NOUNS[root] then
            return not isEndOfDialogue(punctuation)
        elseif word:sub(-3) == "es'" then
            root = body:sub(1, -3)
            if Wordlist.NOUNS[root] then
                return not isEndOfDialogue(punctuation)
            end

            root = body:sub(1, -4)
            if word:sub(-4) == "ves'" and (Wordlist.NOUNS[root.."f"] or Wordlist.NOUNS[root.."fe"]) then
                return not isEndOfDialogue(punctuation)
            elseif word:sub(-4) == "ies'" and Wordlist.NOUNS[root.."y"] then
                return not isEndOfDialogue(punctuation)
            end
        end
    elseif word:sub(-3) == "in'" then
        local root = body:sub(1, -3)
        if Wordlist.isValidWord(body.."g") or Wordlist.VERBS[root] or Wordlist.VERBS[root.."e"] then
            return true
        end

        root = body:sub(1, -4)
        if word:sub(-4) == "yin'" and Wordlist.VERBS[root.."ie"] then
            return true
        elseif word:sub(-5) == "ckin'" and Wordlist.VERBS[root] then
            return true
        elseif word:sub(-4, -4) == word:sub(-5, -5) and Wordlist.VERBS[root] then
            return true
        end
    end

    return false
end

import "Dandiron.RpFilter.Wordlist"
import "Dandiron.RpFilter.Diacritics"

Contraction = {}

--[[
local HEADLESS_WORDS = {
    ["'aporth"] = true,
    ["'aporths"] = true,
    ["'bouta"] = true,
    ["'boutcha"] = true,
    ["'boutchu"] = true,
    ["'boutta"] = true,
    ["'cept"] = true,
    ["'choo"] = true,
    ["'dswounds"] = true,
    ["'em"] = true,
    ["'fore"] = true,
    ["'fraid"] = true,
    ["'fro"] = true,
    ["'kay"] = true,
    ["'mongst"] = true,
    ["'neath"] = true,
    ["'nother"] = true,
    ["'nuff"] = true,
    ["'onna"] = true,
    ["'pologies"] = true,
    ["'pologise"] = true,
    ["'pologising"] = true,
    ["'pologize"] = true,
    ["'pologizing"] = true,
    ["'pology"] = true,
    ["'pon"] = true,
    ["'sall"] = true,
    ["'sblood"] = true,
    ["'scuse"] = true,
    ["'sfar"] = true,
    ["'sfoot"] = true,
    ["'spectable"] = true,
    ["'spectably"] = true,
    ["'spired"] = true,
    ["'spires"] = true,
    ["'spiring"] = true,
    ["'tis"] = true,
    ["'tshall"] = true,
    ["'tude"] = true,
    ["'twas"] = true,
    ["'tween"] = true,
    ["'twere"] = true,
    ["'twill"] = true,
    ["'twixt"] = true,
    ["'twould"] = true,
}

-- These words are valid when h is prepended, but far less likely
local COMMON_WORDS = {
    ["am"] = true,
    ["is"] = true,
}

---Fails if dialogue starts with 'ow, my shin hurts...'
---@param speechMark string apostrophe preceding the word
---@param word string word beginning with apostrophe, e.g. 'round, 'tween
---@return boolean
function Contraction.isValidHeadless(speechMark, word)
    local lowercase = word:lower()
    local body = lowercase:sub(2)

    if HEADLESS_WORDS[lowercase] then
        if Wordlist:isValidWord(body) then
            -- 'round we go vs 'Round are their houses'
            return speechMark:len() == 1 or not IsCapitalized(word)
        else
            return true
        end
    elseif Wordlist:isValidWord("h"..body) then
        if Wordlist:isValidWord(body) then
            -- They asked me 'ow I was. vs 'Ow, that hurts' vs 'Ow are you?
            return speechMark:len() == 1 or (not IsCapitalized(word) and not COMMON_WORDS[body])
        else
            return true
        end
    end

    return false
end
]]

---Returns true for '...potatoes'', '...potatoes'.', '...potatoes',' but not '...potatoes'
---@param punctuation any
---@return boolean
local function isEndOfDialogue(punctuation)
    if punctuation:len() == 0 then
        return false
    end

    if punctuation:sub(1, 1) == "'" or punctuation:find("[%.%?%-,!]+'") then
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
        if (IsCapitalized(word) and not Wordlist:isValidWord(body)) or Wordlist.NOUNS[word:sub(1, -2)] or Wordlist.NOUNS[root] then
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
        if Wordlist:isValidWord(body.."g") or Wordlist.VERBS[root] or Wordlist.VERBS[root.."e"] then
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

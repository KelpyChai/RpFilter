local upperDiacritics = "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞß"
local lowerDiacritics = "àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"

UPPER_CLASS = "A-Z" .. upperDiacritics
LOWER_CLASS = "a-z" .. lowerDiacritics

-- Standard word characters extended with diacritics
WORD_CLASS = "A-Za-z0-9" .. upperDiacritics .. lowerDiacritics

---@param word string
---@return boolean
function IsCapitalized(word)
    return word:match("^'?["..UPPER_CLASS.."]") ~= nil
end

function HasDiacritics(word)
    return word:find("["..lowerDiacritics..upperDiacritics.."]")
end

---Rounds to the nearest integer
---@param val number
---@return number
function Round(val)
    return val >= 0 and math.floor(val + 0.5) or math.ceil(val - 0.5)
end

---Returns hexcode representation of color with red, green, blue within [0, 255]
---@param color table
---@return string
function ToHexColor(color)
    return ("#%02X%02X%02X"):format(Round(color.red), Round(color.green), Round(color.blue))
end

---Wraps text in an RGB tag
---@param text string
---@param color table
---@return string
function AddRgb(text, color)
    return "<rgb=" .. ToHexColor(color) .. ">" .. text .. "</rgb>"
end

---Underlines text surrounded by asterisks
---
---**Warning**: this function cannot handle text with xml tags
---@param text string
---@return string
function UnderlineAsterisks(text)
    if text:find("*", 1, true) then
        local pattern = ("%*([^%s%*]*)([%s][^%*]-)([^%s%*]*)%*"):format(WORD_CLASS, WORD_CLASS, WORD_CLASS)
        text = text:gsub(pattern, "%1<u>%2</u>%3")
    end
    return text
end

---Replaces two hyphens with em dash
---
---**Warning**: em dashes confuse string methods because they are not ASCII characters
---@param text string
---@return string
function ReplaceEmDash(text)
    return (text:gsub("%-%-+", "—"))
end

---Trims leading and trailing whitespace
---@param text string
---@return string
function Strip(text)
    return text:match("^%s*(.-)%s*$")
end

function ComposeFuncs(x, ...)
    for _, f in ipairs({...}) do
        x = f(x)
    end
    return x
end

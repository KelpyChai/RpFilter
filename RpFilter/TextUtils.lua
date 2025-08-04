import "Dandiron.RpFilter.Diacritics"

local function toHexColor(color)
    return string.format(
        "#%02X%02X%02X",
        math.floor(color.red + 0.5),
        math.floor(color.green + 0.5),
        math.floor(color.blue + 0.5)
    )
end

---Wraps text in an RGB tag
---@param text string
---@param color table
---@return string
function AddRgb(text, color)
    return "<rgb=" .. toHexColor(color) .. ">" .. text .. "</rgb>"
end

---If setting is enabled, underline text with asterisks
---@param text any
---@return any
function UnderlineAsterisks(text)
    if Settings.options.isEmphasisUnderlined and text:find("%*") then
        text = text:gsub("%*([^"..WordChars.."%*]*)(["..WordChars.."][^%*]-)([^"..WordChars.."%*]*)%*", "%1<u>%2</u>%3")
    end
    return text
end

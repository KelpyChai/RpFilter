import "Dandiron.RpFilter.Diacritics"

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
    return string.format("#%02X%02X%02X", Round(color.red), Round(color.green), Round(color.blue))
end

---Wraps text in an RGB tag
---@param text string
---@param color table
---@return string
function AddRgb(text, color)
    return "<rgb=" .. ToHexColor(color) .. ">" .. text .. "</rgb>"
end

---If setting is enabled, underline text with asterisks
---@param text string
---@return string
function UnderlineAsterisks(text)
    if Settings.options.isEmphasisUnderlined and text:find("%*") then
        text = text:gsub("%*([^"..WordChars.."%*]*)(["..WordChars.."][^%*]-)([^"..WordChars.."%*]*)%*", "%1<u>%2</u>%3")
    end
    return text
end

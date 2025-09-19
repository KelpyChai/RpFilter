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

---Underlines text surrounded by asterisks
---@param text string
---@return string
function UnderlineAsterisks(text)
    if text:find("%*") then
        text = text:gsub("%*([^"..WordChars.."%*]*)(["..WordChars.."][^%*]-)([^"..WordChars.."%*]*)%*", "%1<u>%2</u>%3")
    end
    return text
end

---Replaces two hyphens with em dash
---@param text any
---@return unknown
function ReplaceEmDash(text)
    return (text:gsub("%-%-", "—"))
end

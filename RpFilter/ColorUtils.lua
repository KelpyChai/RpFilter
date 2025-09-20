-- Taken from https://gist.github.com/ciembor/1494530

---Converts an RGB color value to HSL. Conversion formula
---adapted from http://en.wikipedia.org/wiki/HSL_color_space.
---Assumes r, g, and b are contained in the set [0, 255] and
---returns HSL in the set [0, 1].
---@param color table RGB in the set [0, 255]
---@return table result HSL in the set [0, 1]
function RgbToHsl(color)
    local result = {
        -- h = nil,
        -- s = nil,
        -- l = nil
    }

    local r, g, b = color.r/255, color.g/255, color.b/255

    local max = math.max(r, g, b)
    local min = math.min(r, g, b)

    local avg = (max + min) / 2
    result.h, result.s, result.l = avg, avg, avg

    if max == min then
        result.h, result.s = 0, 0 -- achromatic
    else
        local diff = max - min
        if result.l > 0.5 then
            result.s = diff / (2 - max - min)
        else
            result.s = diff / (max + min)
        end

        if max == r then
            result.h = (g - b) / diff + (g < b and 6 or 0)
        elseif max == g then
            result.h = (b - r) / diff + 2
        elseif max == b then
            result.h = (r - g) / diff + 4
        end

        result.h = (result.h / 6) % 1
    end

    return result
end

------------------------------------------------------------------------

---Converts an HUE to r, g or b.
---@param p number
---@param q number
---@param t number
---@return number p float in the set [0, 1]
local function hueToRgb(p, q, t)
    if t < 0 then
        t = t + 1
    end
    if t > 1 then
        t = t - 1
    end
    if t < 1/6 then
        return p + (q - p) * 6 * t
    end
    if t < 1/2 then
        return q
    end
    if t < 2/3 then
        return p + (q - p) * (2/3 - t) * 6
    end
    return p
end

------------------------------------------------------------------------

---Converts an HSL color value to RGB. Conversion formula
---adapted from http://en.wikipedia.org/wiki/HSL_color_space.
---Assumes h, s, and l are contained in the set [0, 1] and
---returns RGB in the set [0, 255].
---@param hsl table HSL in the set [0, 1]
---@return table result RGB in the set [0, 255]
function HslToRgb(hsl)
    local result = {
        -- r = nil,
        -- g = nil,
        -- b = nil
    }

    local h, s, l = hsl.h, hsl.s, hsl.l

    if s == 0 then
        result.r, result.g, result.b = l * 255, l * 255, l * 255 -- achromatic
    else
        local q = (l < 0.5) and (l * (1 + s)) or (l + s - l * s)
        local p = 2 * l - q
        result.r = hueToRgb(p, q, h + 1/3) * 255
        result.g = hueToRgb(p, q, h) * 255
        result.b = hueToRgb(p, q, h - 1/3) * 255
    end

    return result
end

local function clamp(val, min, max)
    return math.max(min, math.min(val, max))
end

function AdjustHsl(color, delta)
    local hsl = RgbToHsl({r = color.red, g = color.green, b = color.blue})
    hsl.h = (hsl.h + (delta.h or 0)) % 1
    hsl.s = clamp(hsl.s + (delta.s or 0), 0, 1)
    hsl.l = clamp(hsl.l + (delta.l or 0), 0, 1)
    local rgb = HslToRgb(hsl)
    return {red = rgb.r, green = rgb.g, blue = rgb.b}
end

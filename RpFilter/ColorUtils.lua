-- sRGB values to linear intensities
local function srgbToLinear(x)
    return x < 0.04045 and x / 12.92 or ((x + 0.055) / 1.055) ^ 2.4
end

-- Linear intensities to sRGB values
local function linearToSrgb(x)
    return x < 0.0031308 and x * 12.92 or (x ^ (1 / 2.4)) * 1.055 - 0.055
end

---@param color {r:number, g:number, b:number} RGB table where r,g,b in [0, 255]
---@return table
local function rgbToLinear(color)
    return {
        r = srgbToLinear(color.r / 255),
        g = srgbToLinear(color.g / 255),
        b = srgbToLinear(color.b / 255)
    }
end

local function linearToRgb(color)
    local r, g, b = color.r, color.g, color.b

    local max = math.max(r, g, b)
    if max > 1 then
        r, g, b = r / max, g / max, b / max
    end
    r, g, b = math.max(r, 0), math.max(g, 0), math.max(b, 0)

    return {
        r = linearToSrgb(r) * 255,
        g = linearToSrgb(g) * 255,
        b = linearToSrgb(b) * 255
    }
end

local function linearToOklab(color)
    local r, g, b = color.r, color.g, color.b

    local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
	local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
	local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    local l_ = l ^ (1 / 3)
    local m_ = m ^ (1 / 3)
    local s_ = s ^ (1 / 3)

    return {
        L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
    }
end

local function oklabToLinear(color)
    local L, a, b = color.L, color.a, color.b

    local l_ = L + 0.3963377774 * a + 0.2158037573 * b
    local m_ = L - 0.1055613458 * a - 0.0638541728 * b
    local s_ = L - 0.0894841775 * a - 1.2914855480 * b

    local l = l_ ^ 3
    local m = m_ ^ 3
    local s = s_ ^ 3

    return {
		r =  4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
		g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
		b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    }
end

local function oklabToOklch(color)
    local L, a, b = color.L, color.a, color.b

    -- Calculate chroma as the magnitude of the (a, b) vector.
    local C = (a ^ 2 + b ^ 2) ^ (1 / 2)
    -- Calculate hue in radians.
    local h = math.atan2(b, a) % (2 * math.pi)

    return { L = L, C = C, h = h }
end

local function oklchToOklab(color)
    return {
        L = color.L,
        a = color.C * math.cos(color.h),
        b = color.C * math.sin(color.h)
    };
end

---@param color {red: number, green: number, blue: number}
---@return {L: number, C: number, h: number}
local function rgbToOklch(color)
    return ComposeFuncs(color, rgbToLinear, linearToOklab, oklabToOklch)
end

---@param color {L: number, C: number, h: number}
---@return {r: number, g: number, b: number}
local function oklchToRgb(color)
    return ComposeFuncs(color, oklchToOklab, oklabToLinear, linearToRgb)
end

---@param color {red: number, green: number, blue: number}
---@param hueShift number
---@return {red: number, green: number, blue: number}
function AdjustContrast(color, hueShift)
    local oklch = rgbToOklch({r = color.red, g = color.green, b = color.blue})

    -- y = pi/2 * cos(x + 5/6*pi) + pi/2 where x is hue in radians, y a measure of coolness
    -- y = 2(1-m)/pi^3*x^3 - 3(1-m)/pi^2*x^2 + 1 where x is coolness, y is shift factor

    -- c as a measure of coolness in [0, pi]
    local c = math.pi/2 * math.cos(oklch.h + 5/6 * math.pi) + math.pi/2
    -- maximum shift factor -- already tweaked, do not alter without good cause
    local m = 1.75
    local shiftFactor = 2*(1-m)/math.pi^3 * c^3 - 3*(1-m)/math.pi^2 * c^2 + 1
    oklch.h = (oklch.h + shiftFactor * hueShift * (2 * math.pi)) % (2 * math.pi)

    local rgb = oklchToRgb(oklch)
    return {red = rgb.r, green = rgb.g, blue = rgb.b}
end

local function clamp(val, min, max)
    return math.max(min, math.min(val, max))
end

---Assigns colors two-thirds of a revolution apart, going around the color wheel
---in turn, alternating between adding and subtracting hue
---Only works for integer shiftFactor in [0, 11]
---@param color {red: number, green: number, blue: number}
---@param shiftFactor number
---@return {red: number, green: number, blue: number}
function AdjustRainbow(color, shiftFactor)
    local oklch = rgbToOklch({r = color.red, g = color.green, b = color.blue})
    local pi, floor, cos = math.pi, math.floor, math.cos

    local hueRef = (shiftFactor % 3) * (2/3)*pi + oklch.h
    shiftFactor = floor(shiftFactor / 3)
    shiftFactor = shiftFactor % 2 == 0 and -shiftFactor/2 or (shiftFactor + 1)/2

    oklch.h = (hueRef + shiftFactor * (2*pi) / 12) % (2*pi)

    local maxShift = 0.03
    local lightShift = maxShift/2 * (-cos(oklch.h - pi/2) + 1)
    oklch.L = clamp(oklch.L + lightShift, 0.54, 0.75)
    oklch.C = clamp(oklch.C, 0.16, 0.45)

    local rgb = oklchToRgb(oklch)
    return {red = rgb.r, green = rgb.g, blue = rgb.b}
end

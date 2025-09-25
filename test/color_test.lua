
require "Dandiron.RpFilter.ColorUtils"

local HSL_VALUES = {0, 1/255, 0.5, 254/255, 1}
local RGB_VALUES = {0, 1, 128, 254, 255}

---Performs shallow equality check
---@param c1 table
---@param c2 table
---@return boolean
local function areColorsEqual(c1, c2)
    if c1 == c2 then return true end
    if type(c1) ~= "table" or type(c2) ~= "table" then return false end

    local keys = {}
    for k, _ in pairs(c1) do keys[k] = true end
    for k, _ in pairs(c2) do keys[k] = true end

    local epsilon = 1e-6
    for k, _ in pairs(keys) do
        -- if c1[k] ~= c2[k] then return false end
        if math.abs(c1[k] - c2[k]) >= epsilon then return false end
    end
    return true
end

local function HslErrMsg(before, after)
    return string.format(
        "\nBefore: HSL(%f, %f, %f)\nAfter: HSL(%f, %f, %f)",
        before.h, before.s, before.l, after.h, after.s, after.l
    )
end

local function testHslRoundTrip()
    for _, H in ipairs(HSL_VALUES) do
        for _, S in ipairs(HSL_VALUES) do
            for _, L in ipairs(HSL_VALUES) do
                local before = {h = H, s = S, l = L}
                local after = RgbToHsl(HslToRgb(before))

                if before.l == 0 or before.l == 1 then before.s = 0 end
                if before.h == 1 then before.h = 0 end
                if before.s == 0 then before.h = after.h end

                assert(areColorsEqual(before, after), HslErrMsg(before, after))
            end
        end
    end
end

local function RgbErrMsg(before, after)
    return string.format(
        "\nBefore: RGB(%f, %f, %f)\nAfter: RGB(%f, %f, %f)",
        before.r, before.g, before.b, after.r, after.g, after.b
    )
end

local function testRgbRoundTrip()
    local before = {}

    for _, R in ipairs(RGB_VALUES) do
        before.r = R
        for _, G in ipairs(RGB_VALUES) do
            before.g = G
            for _, B in ipairs(RGB_VALUES) do
                before.b = B

                local after = HslToRgb(RgbToHsl(before))

                assert(areColorsEqual(before, after), RgbErrMsg(before, after))
            end
        end
    end
end

local function test()
    testHslRoundTrip()
    testRgbRoundTrip()
end

if ... == nil then
    test()
end

return test

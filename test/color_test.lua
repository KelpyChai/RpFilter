
require "Dandiron.RpFilter.ColorUtils"
require "Dandiron.RpFilter.TextUtils"

local L_VALUES = {0.1, 0.15, 0.5, 0.85, 0.9}
local C_VALUES = {0.05, 0.06, 0.15, 0.29, 0.3}
local H_VALUES = {0, 0.1, math.pi, 2*math.pi - 0.1, 2*math.pi}
local RGB_VALUES = {0, 1, 128, 254, 255}

---Performs shallow equality check
---@param c1 table
---@param c2 table
---@return boolean
local function isRgbEqual(c1, c2)
    if c1 == c2 then return true end
    if type(c1) ~= "table" or type(c2) ~= "table" then return false end

    local keys = {}
    for k, _ in pairs(c1) do keys[k] = true end
    for k, _ in pairs(c2) do keys[k] = true end

    local epsilon = 5 * 1e-4
    for k, _ in pairs(keys) do
        if math.abs(c1[k] - c2[k]) >= epsilon then return false end
    end
    return true
end

local function isOklchEqual(c1, c2)
    if c1 == c2 then return true end
    if type(c1) ~= "table" or type(c2) ~= "table" then return false end

    local epsilons = {L = 0.003, C = 0.005, h = 0.0035}
    for k, epsilon in pairs(epsilons) do
        if math.abs(c1[k] - c2[k]) >= epsilon then return false end
    end
    return true
end

local function OklchErrMsg(before, after)
    return string.format(
        "\nBefore: Oklch(%f, %f, %f)\nAfter: Oklch(%f, %f, %f)",
        before.L, before.C, before.h, after.L, after.C, after.h
    )
end

local function testOklchRoundTrip()
    local before = {}

    for _, L in ipairs(L_VALUES) do
        before.L = L
        for _, C in ipairs(C_VALUES) do
            before.C = C
            for _, h in ipairs(H_VALUES) do
                before.h = h

                local after = RgbToOklch(OklchToRgb(before))

                if not isOklchEqual(before, after) then
                    print(OklchErrMsg(before, after))
                end
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

                local after = OklchToRgb(RgbToOklch(before))

                assert(isRgbEqual(before, after), RgbErrMsg(before, after))
            end
        end
    end
end

local function test()
    testOklchRoundTrip()
    testRgbRoundTrip()
end

if ... == nil then
    test()
end

return test

-- Modified from Cube's functions
-- Color Picker class by Galuhad

import "Dandiron.RpFilter.Location"

local loadData = Turbine.PluginData.Load
local saveData = Turbine.PluginData.Save
local CharacterScope = Turbine.DataScope.Character
local AccountScope = Turbine.DataScope.Account

Settings = {}

local SETTINGS_FILE_NAME = "RpFilterSettings"
local GLOBAL_SETTINGS_FILE_NAME = "RpFilterGlobalSettings"

local DEFAULT_SETTINGS = {
    sayColor = {
        red = 210,
        green = 210,
        blue = 210,
    },
    emoteColor = {
        red = 210,
        green = 210,
        blue = 210,
    },
    options = {
        isSameColorUsed = false,
        areEmotesContrasted = false,
        areEmotesRainbow = false,
        isDialogueColored = false,
        isEmphasisUnderlined = false,
    }
}

local sayColor, emoteColor, options

---Returns a deep copy of an acyclic table without metatables or mutable keys
---@param obj table
---@return table
local function deepcopy(obj)
    if type(obj) ~= "table" then return obj end

    local copy = {}
    for key, val in pairs(obj) do
        copy[key] = type(val) == "table" and deepcopy(val) or val
    end
    return copy
end

function Settings.getSayColor()
    return options.isSameColorUsed and Settings.getEmoteColor() or deepcopy(sayColor)
end

function Settings.getEmoteColor()
    return deepcopy(emoteColor)
end

function Settings.getOptions()
    return deepcopy(options)
end

local function mergeTable(t1, t2)
    local merged = deepcopy(t1)
    for key, val in pairs(t2) do
        merged[key] = type(val) == "table" and deepcopy(val) or val
    end
    return merged
end

function Settings.updateOptions(newOptions)
    options = mergeTable(options, newOptions)
end

function Settings.setEmoteColor(newColor)
    emoteColor = newColor
    if options.isSameColorUsed then sayColor = newColor end
end

function Settings.setSayColor(newColor)
    sayColor = newColor
    if options.isSameColorUsed then emoteColor = newColor end
end

local function filterOptions(data)
    local filtered = {}
    for key, val in pairs(data) do
        if type(val) == "boolean" then
            filtered[key] = val
        end
    end
    return filtered
end

local function loadSettings(data)
    options = data.options or filterOptions(data)
    Settings.setSayColor(data.sayColor)
    Settings.setEmoteColor(data.emoteColor)
end

function Settings.isFirstTime()
    return loadData(CharacterScope, SETTINGS_FILE_NAME) == nil
end

function Settings.loadSync()
    local data =
        loadData(CharacterScope, SETTINGS_FILE_NAME) or
        loadData(AccountScope, GLOBAL_SETTINGS_FILE_NAME) or
        deepcopy(DEFAULT_SETTINGS)

    loadSettings(data)
    if data.location then Location.setCurrent(data.location) end
end

function Settings.loadGlobalAsync(dataLoadHandler)
    print("Waiting to load account settings...")
    loadData(AccountScope, GLOBAL_SETTINGS_FILE_NAME, function (data)
        if data then
            loadSettings(data)
            dataLoadHandler()
            print("Account settings loaded")
        else
            print("Account settings not found")
        end
    end)
end

local function getData()
    return deepcopy({sayColor = sayColor, emoteColor = emoteColor, options = options})
end

function Settings.saveSync()
    local data = getData()
    if not Location.isInstanced() then data.location = Location.getCurrent() end
    saveData(CharacterScope, SETTINGS_FILE_NAME, data)
    print("RP Filter: saved settings")
end

function Settings.saveGlobalAsync()
    saveData(AccountScope, GLOBAL_SETTINGS_FILE_NAME, getData(), function (success, message)
        print(success and "Account settings saved" or message)
    end)
end

-- function Settings.restoreDefault()
--     loadSettings(deepcopy(DEFAULT_SETTINGS))
-- end

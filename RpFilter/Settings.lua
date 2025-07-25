-- Modified from Cube's functions
-- Color Picker class by Galuhad

import "Turbine.UI.Lotro"

local SETTINGS_FILE_NAME = "RpFilterSettings"
local GLOBAL_SETTINGS_FILE_NAME = "RpFilterGlobalSettings"
local SETTINGS_DATA_SCOPE = Turbine.DataScope.Character
local GLOBAL_SETTINGS_DATA_SCOPE = Turbine.DataScope.Account

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
    -- italicsColor
}

Settings = {
    options = {}
}

local function deepcopy(object)
    local copies = {}

    local function copy(object)
        if type(object) ~= "table" then
            return object
        elseif copies[object] then
            return copies[object]
        end
        local newCopy = {}
        copies[object] = newCopy
        for key, value in pairs(object) do
            newCopy[copy(key)] = copy(value)
        end
        return setmetatable(newCopy, getmetatable(object))
    end

    return copy(object)
end

function Settings:load()
    local loadedSettings = Turbine.PluginData.Load(
        SETTINGS_DATA_SCOPE,
        SETTINGS_FILE_NAME
    )

    if type(loadedSettings) ~= "table" then
        loadedSettings = Turbine.PluginData.Load(
            GLOBAL_SETTINGS_DATA_SCOPE,
            GLOBAL_SETTINGS_FILE_NAME
        )
    end

    if type(loadedSettings) ~= 'table' then
        self.options = deepcopy(DEFAULT_SETTINGS)
        Turbine.Shell.WriteLine("RP Filter: loaded default settings")
    else
        self.options = loadedSettings
        Turbine.Shell.WriteLine("RP Filter: loaded settings")
    end
end

function Settings:save()
    Turbine.PluginData.Save(
        SETTINGS_DATA_SCOPE,
        SETTINGS_FILE_NAME,
        self.options
    )
    Turbine.Shell.WriteLine("RP Filter: saved settings")
end

function Settings:saveGlobal()
    Turbine.PluginData.Save(
        GLOBAL_SETTINGS_DATA_SCOPE,
        GLOBAL_SETTINGS_FILE_NAME,
        self.options
    )
end

function Settings:restoreDefault()
    self.options = deepcopy(DEFAULT_SETTINGS)
end

function Settings:getSayColor()
    return self.options.sayColor
end

function Settings:getEmoteColor()
    return self.options.emoteColor
end

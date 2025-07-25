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

local function createBackground(colorPickerWindow)
    local background = Turbine.UI.Control();
    background:SetParent(colorPickerWindow);
    background:SetSize(284, 145 - 38);
    background:SetPosition(8, 38);
    background:SetBackColor(Turbine.UI.Color(0.1, 0.1, 0.1));
    return background
end

local function createColorPickerWindow()
    -- the color picker window
    local colorPickerWindow = Turbine.UI.Lotro.Window();
    colorPickerWindow:SetSize(300,180);
    colorPickerWindow:SetPosition(100,100);
    colorPickerWindow:SetText("Colour Picker");
    createBackground(colorPickerWindow)
    return colorPickerWindow
end

local function createColorPicker(colorPickerWindow)
    local colorPicker = ColorPicker.Create();
    colorPicker:SetParent(colorPickerWindow);
    colorPicker:SetSize(280, 70);
    colorPicker:SetPosition(10, 40);
    return colorPicker
end

local function createColorPreview(colorPickerWindow)
    local colorPreview = Turbine.UI.Control();
    colorPreview:SetParent(colorPickerWindow);
    colorPreview:SetSize(23,23);
    colorPreview:SetPosition(95,120);
    return colorPreview
end

local function createColorLabel(colorPickerWindow)
    local colorLabelFont = Turbine.UI.Lotro.Font.TrajanPro14;
    local colorLabelColor = Turbine.UI.Color(229 / 255, 209 / 255, 136 / 255);

    -- selected color hex value
    local colorLabel = Turbine.UI.Label();
    colorLabel:SetParent(colorPickerWindow);
    colorLabel:SetPosition(125,120);
    colorLabel:SetSize(220,23);
    colorLabel:SetForeColor(colorLabelColor);
    colorLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
    colorLabel:SetFont(colorLabelFont);
    return colorLabel
end

local function createSaveButton(colorPickerWindow)
    local saveButton = Turbine.UI.Lotro.Button();
    saveButton:SetParent(colorPickerWindow);
    saveButton:SetText("Save");
    saveButton:SetPosition(100, 150);
    saveButton:SetWidth(100);
    return saveButton
end

local function showColorPicker(color, window)
    local red, green, blue = color.red, color.green, color.blue -- 0 to 255

    local turbineColor = Turbine.UI.Color(red / 255, green / 255, blue / 255)
    window.colorPreview:SetBackColor(turbineColor)

    local hexPattern = "Hex: #%02x%02x%02x"
    window.colorLabel:SetText(string.format(hexPattern, red, green, blue))

    function window.saveButton.Click(sender, args)
        local newRed, newGreen, newBlue = window.colorPicker:GetRGBColor()
        color.red, color.blue, color.green = newRed, newBlue, newGreen
    end

    window.colorPickerWindow:SetVisible(true);
    -- Make sure the Color Picker window is on top
    window.colorPickerWindow:SetZOrder(1);
    window.colorPickerWindow:SetZOrder(0);
end

function DrawOptionsPanel()
    local colorPickerWindow = createColorPickerWindow()
    local window = {}
    window.colorPickerWindow = colorPickerWindow
    window.colorPicker = createColorPicker(colorPickerWindow)
    window.colorPreview = createColorPreview(colorPickerWindow)
    window.colorLabel = createColorLabel(colorPickerWindow)
    window.saveButton = createSaveButton(colorPickerWindow)

    function window.colorPicker:LeftClick()
        window.colorPreview:SetBackColor(self:GetTurbineColor());
        window.colorLabel:SetText("Hex: #" .. self:GetHexColor());
    end

    local panel = Turbine.UI.Control()
    function plugin.GetOptionsPanel() return panel end

    -- panel:SetBackColor(Turbine.UI.Color(0.1, 0.1, 0.1)); -- RGB, 0..1 = 0..255
    panel:SetSize(250, 300);

    local leftMargin = 20;
    local controlTop = 20;

    -- add a button to open the color picker to choose the say color
    local changeSayColor = Turbine.UI.Lotro.Button();
    changeSayColor:SetParent(panel);
    changeSayColor:SetText("Change Say Colour");
    changeSayColor:SetPosition(leftMargin, controlTop);
    changeSayColor:SetWidth(200);
    function changeSayColor.Click(sender, args)
        showColorPicker(Settings:getSayColor(), window)
    end
    controlTop = controlTop + 40;

    -- add a button to open the color picker to choose the emote color
    local changeEmoteColor = Turbine.UI.Lotro.Button();
    changeEmoteColor:SetParent(panel);
    changeEmoteColor:SetText("Change Emote Colour");
    changeEmoteColor:SetPosition(leftMargin, controlTop);
    changeEmoteColor:SetWidth(200);
    function changeEmoteColor.Click(sender, args)
        showColorPicker(Settings:getEmoteColor(), window)
    end
    controlTop = controlTop + 40;
end

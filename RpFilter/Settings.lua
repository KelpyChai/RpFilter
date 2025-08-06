-- Modified from Cube's functions
-- Color Picker class by Galuhad

import "Turbine.UI.Lotro"

import "Dandiron.RpFilter.ColorPicker"
import "Dandiron.RpFilter.Color"

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
    isSameColorUsed = false,
    areEmotesContrasted = false,
    isDialogueColored = false,
    isEmphasisUnderlined = false,
    isEmphasisAccented = false
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
        -- Turbine.Shell.WriteLine("RP Filter: loaded default settings")
    else
        self.options = loadedSettings
        -- Turbine.Shell.WriteLine("RP Filter: loaded settings")
    end
end

function Settings:loadGlobal()
    Turbine.Shell.WriteLine("Waiting to load account settings...")
    Turbine.PluginData.Load(
        GLOBAL_SETTINGS_DATA_SCOPE,
        GLOBAL_SETTINGS_FILE_NAME,
        function(loadedData)
            if type(loadedData) == "table" then
                self.options = loadedData
                Turbine.Shell.WriteLine("Account settings loaded")
            else
                Turbine.Shell.WriteLine("Account settings not found")
            end
        end
    )
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
    Turbine.Shell.WriteLine("Account settings saved")
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

function Settings:getLighterColor()
    return self.options.lighter
end

function Settings:getDarkerColor()
    return self.options.darker
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

local function clamp(num, minVal, maxVal)
    return math.max(minVal, math.min(num, maxVal))
end

local function adjustColor(rgb, hueDiff, lightDiff)
    local hsl = RgbToHsl(rgb)
    hsl.h = (hsl.h + hueDiff) % 1
    hsl.l = clamp(hsl.l + lightDiff, 0, 1)
    return HslToRgb(hsl)
end

local function contrastColors()
    Settings.options.lighter = adjustColor(Settings:getEmoteColor(), -0.014, 0.01)
    Settings.options.darker = adjustColor(Settings:getEmoteColor(), 0.014, -0.008)
end

local function showColorPicker(color, window)
    local red, green, blue = color.red, color.green, color.blue -- 0 to 255

    local turbineColor = Turbine.UI.Color(red / 255, green / 255, blue / 255)
    window.colorPreview:SetBackColor(turbineColor)

    local hexPattern = "Hex: #%02x%02x%02x"
    window.colorLabel:SetText(string.format(hexPattern, red, green, blue))

    function window.saveButton.Click(sender, args)
        local newRed, newGreen, newBlue = window.colorPicker:GetRGBColor()
        if not newRed then
            newRed, newGreen, newBlue = red, green, blue
        end

        if Settings.options.isSameColorUsed then
            local sayColor = Settings.options.sayColor
            local emoteColor = Settings.options.emoteColor
            sayColor.red, sayColor.blue, sayColor.green = newRed, newBlue, newGreen
            emoteColor.red, emoteColor.blue, emoteColor.green = newRed, newBlue, newGreen
        else
            color.red, color.blue, color.green = newRed, newBlue, newGreen
        end
        if Settings.options.areEmotesContrasted then
            contrastColors()
        end
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

    local options = Turbine.UI.Control()
    function plugin.GetOptionsPanel() return options end

    -- options:SetBackColor(Turbine.UI.Color(0.1, 0.1, 0.1)); -- RGB, 0..1 = 0..255
    options:SetSize(250, 300);

    local leftMargin = 20;
    local controlTop = 20;

    -- add a button to open the color picker to choose the say color
    local changeSayColor = Turbine.UI.Lotro.Button();
    changeSayColor:SetParent(options);
    changeSayColor:SetText("Change Say Colour");
    changeSayColor:SetPosition(leftMargin, controlTop);
    changeSayColor:SetWidth(200);
    function changeSayColor.Click(sender, args)
        showColorPicker(Settings:getSayColor(), window)
    end
    controlTop = controlTop + 40;

    -- add a button to open the color picker to choose the emote color
    local changeEmoteColor = Turbine.UI.Lotro.Button();
    changeEmoteColor:SetParent(options);
    changeEmoteColor:SetText("Change Emote Colour");
    changeEmoteColor:SetPosition(leftMargin, controlTop);
    changeEmoteColor:SetWidth(200);
    function changeEmoteColor.Click(sender, args)
        showColorPicker(Settings:getEmoteColor(), window)
    end
    controlTop = controlTop + 40;

    local useSameColor = Turbine.UI.Lotro.CheckBox()
    useSameColor:SetParent(options)
    useSameColor:SetText(" Use the same colour for says and emotes")
    useSameColor:SetPosition(leftMargin + 20, controlTop)
    useSameColor:SetChecked(Settings.options.isSameColorUsed)
    useSameColor:SetSize(350, 20)
    useSameColor:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    useSameColor:SetFont(Turbine.UI.Lotro.Font.Verdana16);
    function useSameColor:CheckedChanged()
        Settings.options.isSameColorUsed = self:IsChecked()
    end
    controlTop = controlTop + 25

    local contrastEmotes = Turbine.UI.Lotro.CheckBox()
    contrastEmotes:SetParent(options)
    contrastEmotes:SetText(" Give emotes by different characters a subtle contrast")
    contrastEmotes:SetPosition(leftMargin + 20, controlTop)
    contrastEmotes:SetChecked(Settings.options.areEmotesContrasted)
    contrastEmotes:SetSize(500, 20)
    contrastEmotes:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    contrastEmotes:SetFont(Turbine.UI.Lotro.Font.Verdana16);
    function contrastEmotes:CheckedChanged()
        Settings.options.areEmotesContrasted = self:IsChecked()
        if self:IsChecked() then
            contrastColors()
        else
            Settings.options.lighter = nil
            Settings.options.darker = nil
        end
    end
    controlTop = controlTop + 25

    local colorDialogue = Turbine.UI.Lotro.CheckBox()
    colorDialogue:SetParent(options)
    colorDialogue:SetText(" Give dialogue surrounded by 'quotes' the same colour as says")
    colorDialogue:SetPosition(leftMargin + 20, controlTop)
    colorDialogue:SetChecked(Settings.options.isDialogueColored)
    colorDialogue:SetSize(500, 20)
    colorDialogue:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    colorDialogue:SetFont(Turbine.UI.Lotro.Font.Verdana16);
    function colorDialogue:CheckedChanged()
        Settings.options.isDialogueColored = self:IsChecked()
    end
    controlTop = controlTop + 25

    local underlineEmphasis = Turbine.UI.Lotro.CheckBox()
    underlineEmphasis:SetParent(options)
    underlineEmphasis:SetText(" Underline words surrounded by *asterisks*")
    underlineEmphasis:SetPosition(leftMargin + 20, controlTop)
    underlineEmphasis:SetChecked(Settings.options.isEmphasisUnderlined)
    underlineEmphasis:SetSize(350, 20)
    underlineEmphasis:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    underlineEmphasis:SetFont(Turbine.UI.Lotro.Font.Verdana16);
    function underlineEmphasis:CheckedChanged()
        Settings.options.isEmphasisUnderlined = self:IsChecked()
    end
    controlTop = controlTop + 40

    local loadGlobal = Turbine.UI.Lotro.Button();
    loadGlobal:SetParent(options);
    loadGlobal:SetText("Load Account Settings");
    loadGlobal:SetPosition(leftMargin, controlTop);
    loadGlobal:SetWidth(200);
    function loadGlobal.Click(sender, args)
        Settings:loadGlobal()
    end
    controlTop = controlTop + 40;

    local saveGlobal = Turbine.UI.Lotro.Button();
    saveGlobal:SetParent(options);
    saveGlobal:SetText("Save Account Settings");
    saveGlobal:SetPosition(leftMargin, controlTop);
    saveGlobal:SetWidth(200);
    function saveGlobal.Click(sender, args)
        Settings:saveGlobal()
    end
    controlTop = controlTop + 40;
end

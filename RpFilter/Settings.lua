-- Modified from Cube's functions
-- Color Picker class by Galuhad

import "Turbine.UI.Lotro"

import "Dandiron.RpFilter.ColorPicker"
import "Dandiron.RpFilter.ColorUtils"

Settings = {}

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
}

local fields = {}

local function readOnly(table)
    local proxy = {}
    local metatable = {
        __index = table,
        __newindex = function (_, k, v)
            error("attempt to update a read-only table", 2)
        end
    }
    setmetatable(proxy, metatable)
    return proxy
end

local settingsView = readOnly(fields)

---Returns a shallow read-only table of options
---@return table
function Settings.get()
    return settingsView
end

---Returns a modifiable table of options
---@return table
function Settings.getMutable()
    return fields
end

local function setTable(table, newTable)
    for key, _ in pairs(table) do
        table[key] = nil
    end
    for key, val in pairs(newTable) do
        table[key] = val
    end
end

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

function Settings.load()
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
        setTable(fields, deepcopy(DEFAULT_SETTINGS))
        -- print("RP Filter: loaded default settings")
    else
        setTable(fields, loadedSettings)
        -- print("RP Filter: loaded settings")
    end
end

function Settings.loadGlobal()
    print("Waiting to load account settings...")
    Turbine.PluginData.Load(
        GLOBAL_SETTINGS_DATA_SCOPE,
        GLOBAL_SETTINGS_FILE_NAME,
        function (loadedSettings)
            if type(loadedSettings) == "table" then
                setTable(fields, loadedSettings)
                print("Account settings loaded")
            else
                print("Account settings not found")
            end
        end
    )
end

function Settings.save()
    Turbine.PluginData.Save(
        SETTINGS_DATA_SCOPE,
        SETTINGS_FILE_NAME,
        fields
    )
    print("RP Filter: saved settings")
end

function Settings.saveGlobal()
    Turbine.PluginData.Save(
        GLOBAL_SETTINGS_DATA_SCOPE,
        GLOBAL_SETTINGS_FILE_NAME,
        fields
    )
    print("Account settings saved")
end

-- function Settings.restoreDefault()
--     setTable(fields, deepcopy(DEFAULT_SETTINGS))
-- end

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
    local colorLabelColor = Turbine.UI.Color(229/255, 209/255, 136/255);

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

local function contrastColors()
    Settings.getMutable().lighter = AdjustHsl(Settings.get().emoteColor, {h = -0.014, l = 0.01})
    Settings.getMutable().darker = AdjustHsl(Settings.get().emoteColor, {h = 0.014, l = -0.008})
end

local function getNewColor(colorPicker)
    local r, g, b = colorPicker:GetRGBColor()
    return r ~= nil and {red = r, green = g, blue = b} or nil
end

local function setColor(color, new)
    color.red, color.green, color.blue = new.red, new.green, new.blue
end

local function showColorPicker(color, window)
    local turbineColor = Turbine.UI.Color(color.red/255, color.green/255, color.blue/255)
    window.colorPreview:SetBackColor(turbineColor)
    window.colorLabel:SetText("Hex: " .. ToHexColor(color))

    function window.saveButton.Click(sender, args)
        local currColor = getNewColor(window.colorPicker) or color

        if Settings.get().isSameColorUsed then
            setColor(Settings.getMutable().sayColor, currColor)
            setColor(Settings.getMutable().emoteColor, currColor)
        else
            setColor(color, currColor)
        end

        if Settings.get().areEmotesContrasted then
            contrastColors()
        end
    end

    window.colorPickerWindow:SetVisible(true);
    -- Make sure the Color Picker window is on top
    window.colorPickerWindow:SetZOrder(1);
    window.colorPickerWindow:SetZOrder(0);
end

function Settings.DrawOptionsPanel()
    local colorPickerWindow = createColorPickerWindow()
    local window = {
        colorPickerWindow = colorPickerWindow,
        colorPicker = createColorPicker(colorPickerWindow),
        colorPreview = createColorPreview(colorPickerWindow),
        colorLabel = createColorLabel(colorPickerWindow),
        saveButton = createSaveButton(colorPickerWindow),
    }

    function window.colorPicker:LeftClick()
        window.colorPreview:SetBackColor(self:GetTurbineColor());
        window.colorLabel:SetText("Hex: #" .. self:GetHexColor());
    end

    local optionsPanel = Turbine.UI.Control()
    function plugin.GetOptionsPanel() return optionsPanel end

    -- optionsPanel:SetBackColor(Turbine.UI.Color(0.1, 0.1, 0.1)); -- RGB, 0..1 = 0..255
    optionsPanel:SetSize(250, 300);

    local leftMargin = 20;
    local controlTop = 20;

    -- add a button to open the color picker to choose the say color
    local changeSayColor = Turbine.UI.Lotro.Button();
    changeSayColor:SetParent(optionsPanel);
    changeSayColor:SetText("Change Say Colour");
    changeSayColor:SetPosition(leftMargin, controlTop);
    changeSayColor:SetWidth(200);
    function changeSayColor.Click(sender, args)
        showColorPicker(Settings.getMutable().sayColor, window)
    end
    controlTop = controlTop + 40;

    -- add a button to open the color picker to choose the emote color
    local changeEmoteColor = Turbine.UI.Lotro.Button();
    changeEmoteColor:SetParent(optionsPanel);
    changeEmoteColor:SetText("Change Emote Colour");
    changeEmoteColor:SetPosition(leftMargin, controlTop);
    changeEmoteColor:SetWidth(200);
    function changeEmoteColor.Click(sender, args)
        showColorPicker(Settings.getMutable().emoteColor, window)
    end
    controlTop = controlTop + 40;

    local useSameColor = Turbine.UI.Lotro.CheckBox()
    useSameColor:SetParent(optionsPanel)
    useSameColor:SetText(" Use the same colour for says and emotes")
    useSameColor:SetPosition(leftMargin + 20, controlTop)
    useSameColor:SetChecked(Settings.get().isSameColorUsed)
    useSameColor:SetSize(350, 20)
    useSameColor:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    useSameColor:SetFont(Turbine.UI.Lotro.Font.Verdana16);
    function useSameColor:CheckedChanged()
        Settings.getMutable().isSameColorUsed = self:IsChecked()
    end
    controlTop = controlTop + 25

    local contrastEmotes = Turbine.UI.Lotro.CheckBox()
    contrastEmotes:SetParent(optionsPanel)
    contrastEmotes:SetText(" Give emotes by different characters a subtle contrast")
    contrastEmotes:SetPosition(leftMargin + 20, controlTop)
    contrastEmotes:SetChecked(Settings.get().areEmotesContrasted)
    contrastEmotes:SetSize(500, 20)
    contrastEmotes:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    contrastEmotes:SetFont(Turbine.UI.Lotro.Font.Verdana16);
    function contrastEmotes:CheckedChanged()
        Settings.getMutable().areEmotesContrasted = self:IsChecked()
        if self:IsChecked() then
            contrastColors()
        else
            Settings.getMutable().lighter = nil
            Settings.getMutable().darker = nil
        end
    end
    controlTop = controlTop + 25

    local colorDialogue = Turbine.UI.Lotro.CheckBox()
    colorDialogue:SetParent(optionsPanel)
    colorDialogue:SetText(' Give "quoted" dialogue the same colour as says')
    colorDialogue:SetPosition(leftMargin + 20, controlTop)
    colorDialogue:SetChecked(Settings.get().isDialogueColored)
    colorDialogue:SetSize(500, 20)
    colorDialogue:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    colorDialogue:SetFont(Turbine.UI.Lotro.Font.Verdana16);
    function colorDialogue:CheckedChanged()
        Settings.getMutable().isDialogueColored = self:IsChecked()
    end
    controlTop = controlTop + 25

    local underlineEmphasis = Turbine.UI.Lotro.CheckBox()
    underlineEmphasis:SetParent(optionsPanel)
    underlineEmphasis:SetText(" Underline words surrounded by *asterisks*")
    underlineEmphasis:SetPosition(leftMargin + 20, controlTop)
    underlineEmphasis:SetChecked(Settings.get().isEmphasisUnderlined)
    underlineEmphasis:SetSize(350, 20)
    underlineEmphasis:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
    underlineEmphasis:SetFont(Turbine.UI.Lotro.Font.Verdana16);
    function underlineEmphasis:CheckedChanged()
        Settings.getMutable().isEmphasisUnderlined = self:IsChecked()
    end
    controlTop = controlTop + 40

    local loadGlobal = Turbine.UI.Lotro.Button();
    loadGlobal:SetParent(optionsPanel);
    loadGlobal:SetText("Load Account Settings");
    loadGlobal:SetPosition(leftMargin, controlTop);
    loadGlobal:SetWidth(200);
    function loadGlobal.Click(sender, args)
        Settings.loadGlobal()
    end
    controlTop = controlTop + 40;

    local saveGlobal = Turbine.UI.Lotro.Button();
    saveGlobal:SetParent(optionsPanel);
    saveGlobal:SetText("Save Account Settings");
    saveGlobal:SetPosition(leftMargin, controlTop);
    saveGlobal:SetWidth(200);
    function saveGlobal.Click(sender, args)
        Settings.saveGlobal()
    end
    controlTop = controlTop + 40;
end

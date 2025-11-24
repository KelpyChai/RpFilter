import "Turbine.UI.Lotro"

import "Dandiron.RpFilter.Settings"
import "Dandiron.RpFilter.ColorPicker"
import "Dandiron.RpFilter.TextUtils"

local function createBackground(window)
    local background = Turbine.UI.Control()
    background:SetParent(window)
    background:SetSize(284, 145 - 38)
    background:SetPosition(8, 38)
    background:SetBackColor(Turbine.UI.Color(0.1, 0.1, 0.1))
    return background
end

local function createPreview(window)
    local preview = Turbine.UI.Control()
    preview:SetParent(window)
    preview:SetSize(23, 23)
    preview:SetPosition(95, 120)
    return preview
end

local function createLabel(window)
    local PICKER_LABEL_FONT = Turbine.UI.Lotro.Font.TrajanPro14
    local PICKER_LABEL_COLOR = Turbine.UI.Color(229/255, 209/255, 136/255)

    -- selected color hex value
    local label = Turbine.UI.Label()
    label:SetParent(window)
    label:SetPosition(125, 120)
    label:SetSize(220, 23)
    label:SetForeColor(PICKER_LABEL_COLOR)
    label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
    label:SetFont(PICKER_LABEL_FONT)
    return label
end

local function createColorPicker(window, preview, label)
    local colorPicker = ColorPicker.Create()
    colorPicker:SetParent(window)
    colorPicker:SetSize(280, 70)
    colorPicker:SetPosition(10, 40)
    function colorPicker:LeftClick()
        preview:SetBackColor(self:GetTurbineColor())
        label:SetText("Hex: #" .. self:GetHexColor())
    end
    return colorPicker
end

local function getNewColor(colorPicker)
    local r, g, b = colorPicker:GetRGBColor()
    return r and {red = r, green = g, blue = b}
end

local function createSaveButton(window, colorPicker, getColor, setColor)
    local saveButton = Turbine.UI.Lotro.Button()
    saveButton:SetParent(window)
    saveButton:SetText("Save")
    saveButton:SetPosition(100, 150)
    saveButton:SetWidth(100)
    function saveButton:Click()
        setColor(getNewColor(colorPicker) or getColor())
    end
    return saveButton
end

local function createWindow(title)
    local window = Turbine.UI.Lotro.Window()
    window:SetSize(300, 180)
    window:SetPosition(100, 100)
    window:SetText(title)
    createBackground(window)
    return window
end

local function showColorPickerWindow(getColor, window, preview, label)
    local color = getColor()
    local turbineColor = Turbine.UI.Color(color.red/255, color.green/255, color.blue/255)
    preview:SetBackColor(turbineColor)
    label:SetText("Hex: " .. ToHexColor(color))

    window:SetVisible(true)
    -- Make sure the Color Picker window is on top
    window:Activate()
    window:SetWantsKeyEvents(true)

    function window:Closing()
        self:SetWantsKeyEvents(false)
    end
    function window:KeyDown(args)
        if args.Action == Turbine.UI.Lotro.Action.Escape then self:Close() end
    end
end

local function createColorPickerWindow(title, getColor, setColor)
    local window = createWindow(title)
    local preview, label = createPreview(window), createLabel(window)
    local colorPicker = createColorPicker(window, preview, label)
    createSaveButton(window, colorPicker, getColor, setColor)

    return function ()
        showColorPickerWindow(getColor, window, preview, label)
    end
end

function DrawOptionsPanel(options)
    local CHECKBOX_LABEL_FONT = Turbine.UI.Lotro.Font.Verdana16
    local CHECKBOX_HEIGHT = 25
    local BUTTON_HEIGHT, BUTTON_WIDTH = 40, 200

    local optionsPanel = Turbine.UI.Control()
    optionsPanel:SetSize(250, 350)
    function plugin:GetOptionsPanel() return optionsPanel end

    local showSayColorPicker = createColorPickerWindow(
        "Say Colour",
        Settings.getSayColor,
        Settings.setSayColor
    )
    local showEmoteColorPicker = createColorPickerWindow(
        "Emote Colour",
        Settings.getEmoteColor,
        Settings.setEmoteColor
    )

    local leftMargin = 20
    local controlTop = 20

    local function createButton(text, clickHandler)
        local button = Turbine.UI.Lotro.Button()
        button:SetParent(optionsPanel)
        button:SetText(text)
        button:SetPosition(leftMargin, controlTop)
        button:SetWidth(BUTTON_WIDTH)
        button.Click = clickHandler
        controlTop = controlTop + BUTTON_HEIGHT
    end

    ---@param text string
    ---@return LotroCheckBox
    local function createCheckbox(text)
        local checkbox = Turbine.UI.Lotro.CheckBox()
        checkbox:SetParent(optionsPanel)
        checkbox:SetText(text)
        checkbox:SetPosition(leftMargin + 20, controlTop)
        checkbox:SetSize(#text * 9, CHECKBOX_HEIGHT - 5)
        checkbox:SetTextAlignment(Turbine.UI.ContentAlignment.BottomLeft)
        checkbox:SetFont(CHECKBOX_LABEL_FONT)
        controlTop = controlTop + CHECKBOX_HEIGHT
        return checkbox
    end

    -- add a button to open the color picker to choose the say color
    createButton("Choose Say Colour", showSayColorPicker)

    -- add a button to open the color picker to choose the emote color
    createButton("Choose Emote Colour", showEmoteColorPicker)

    local useSameColor = createCheckbox(" Use same colour for says and emotes")
    function useSameColor:CheckedChanged()
        Settings.updateOptions({isSameColorUsed = self:IsChecked()})
    end

    local contrastEmotes = createCheckbox(" Add contrast when emotes alternate between players")
    local rainbowEmotes = createCheckbox(" Give players unique emote colors (up to 12)")

    function contrastEmotes:CheckedChanged()
        local isChecked = self:IsChecked()
        Settings.updateOptions({areEmotesContrasted = isChecked})
        if isChecked then rainbowEmotes:SetChecked(false) end
    end
    function rainbowEmotes:CheckedChanged()
        local isChecked = self:IsChecked()
        Settings.updateOptions({areEmotesRainbow = isChecked})
        if isChecked then contrastEmotes:SetChecked(false) end
    end

    local colorDialogue = createCheckbox(' Give "quoted" dialogue the same colour as says')
    function colorDialogue:CheckedChanged()
        Settings.updateOptions({isDialogueColored = self:IsChecked()})
    end

    local underlineEmphasis = createCheckbox(" Underline words *surrounded* by asterisks")
    function underlineEmphasis:CheckedChanged()
        Settings.updateOptions({isEmphasisUnderlined = self:IsChecked()})
    end

    local lineBreaks = createCheckbox(" Add line breaks between different posters")
    function lineBreaks:CheckedChanged()
        Settings.updateOptions({areNewlinesPrinted = self:IsChecked()})
    end

    local function updateCheckboxes(opts)
        opts = opts or Settings.getOptions()
        useSameColor:SetChecked(opts.isSameColorUsed)
        contrastEmotes:SetChecked(opts.areEmotesContrasted)
        rainbowEmotes:SetChecked(opts.areEmotesRainbow)
        colorDialogue:SetChecked(opts.isDialogueColored)
        underlineEmphasis:SetChecked(opts.isEmphasisUnderlined)
        lineBreaks:SetChecked(opts.areNewlinesPrinted)
    end
    updateCheckboxes(options)

    controlTop = controlTop + (BUTTON_HEIGHT - CHECKBOX_HEIGHT)

    createButton("Load Account Settings", function ()
        Settings.loadGlobalAsync(updateCheckboxes)
    end)

    createButton("Save Account Settings", Settings.saveGlobalAsync)
end

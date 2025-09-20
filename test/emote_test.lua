local Emote = require "Dandiron.RpFilter.Emote"

local BLACK = {red = 0, green = 0, blue = 0}

local SETTINGS_NEITHER = {
    sayColor = BLACK
}
local SETTINGS_COLORED = {
    sayColor = BLACK,
    isDialogueColored = true
}
local SETTINGS_EMPHASIS = {
    sayColor = BLACK,
    isEmphasisUnderlined = true
}
local SETTINGS_BOTH = {
    sayColor = BLACK,
    isDialogueColored = true,
    isEmphasisUnderlined = true
}

local DIALOGUE_CASES = {
    {
        emote = '',
        expected = ''
    },
    {
        emote = '""',
        expected = '""'
    },
    {
        emote = '" "',
        expected = '""'
    },
}

for _, case in pairs(DIALOGUE_CASES) do
    assert(Emote.colorDialogue(case.emote, SETTINGS_NEITHER) == case.expected)
end

import "Turbine.Gameplay"

Emote = {
    MultiPosts = {}
}

local function getLightOrDark(isCurrColorLight)
    if isCurrColorLight then
        return Settings:getLighterColor()
    else
        return Settings:getDarkerColor()
    end
end

---Formats messages from the emote channel, including multi-post emotes
---@param message string
---@return string
function Emote:format(message)
    local name, emote = message:match("^(%a+)%-?%d- (.+)")
    local formattedEmote = message

    -- TODO: Handle these cases

    -- Starting with words like 'tis and 'cause and '90s
    -- /e "Lua is an extension programming language designed to support general procedural programming with data description facilities."
    -- /e | "You know," she mutters, "I was just thinking of that."

    -- /e <very long post> +
    -- /e <even more>

    -- /e "Blah blah blah +"
    -- /e "I'm not done speaking yet!"

    if emote:sub(1, 3) == "'s " then
        formattedEmote = name .. "'s " .. emote:gsub("^'s%s+", "")
    elseif emote:sub(1, 1) == "|" then
        formattedEmote = emote:gsub("^|+%s*", "")
    -- elseif emote:sub(1, 1) == "+" then
    --     formattedEmote = emote:gsub("^%+%s*", "")
    elseif emote:match("^l+ ") then
        formattedEmote = emote:gsub("^l+%s+", "")
    end

    if Settings.options.isEmphasisUnderlined then
        formattedEmote = formattedEmote:gsub("%*([^%w%*]*)([^%W%*][^%*]-)([^%w%*]*)%*", "%1<u>%2</u>%3")
    end

    if Settings.options.areEmotesContrasted then
        local myName = Turbine.Gameplay.LocalPlayer:GetInstance():GetName()
        if name == Emote.currEmoter or
          (name == "You" and Emote.currEmoter == myName) or
          (name == myName and Emote.currEmoter == "You") then
            formattedEmote = AddRgbTag(formattedEmote, getLightOrDark(Emote.isCurrColorLight))
        else
            Emote.currEmoter = name
            Emote.isCurrColorLight = not Emote.isCurrColorLight
            formattedEmote = AddRgbTag(formattedEmote, getLightOrDark(Emote.isCurrColorLight))
        end
        -- print(Emote.currEmoter)
    end

    return formattedEmote
end

    -- Optional features:
    -- Highlight player names and/or make them inspectable
    -- Line break between each post, or between different characters
    -- /clear

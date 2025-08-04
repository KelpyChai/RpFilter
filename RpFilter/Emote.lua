import "Turbine.Gameplay"

Emote = {
    -- multiPosts = {}
}

if Settings.options.areEmotesContrasted then
    Emote.isCurrColorLight = false
end

function Emote:getLightOrDark()
    if self.isCurrColorLight then
        return Settings:getLighterColor()
    else
        return Settings:getDarkerColor()
    end
end

---Formats messages from the emote channel, including multi-post emotes
---@param emote string
---@return string
function Emote:format(emote)
    local name, action = emote:match("^(%a+)%-?%d- (.+)")

    -- TODO: Handle these cases

    -- Starting with words like 'tis and 'cause and '90s
    -- /e "Lua is an extension programming language designed to support general procedural programming with data description facilities."
    -- /e | "You know," she mutters, "I was just thinking of that."

    -- /e <very long post> +
    -- /e <even more>

    -- /e "Blah blah blah +"
    -- /e "I'm not done speaking yet!"

    local firstChar = action:sub(1, 1)
    if action:sub(1, 3) == "'s " then
        emote = name .. "'s " .. action:gsub("^'s%s+", "")
    elseif firstChar == "|" then
        emote = action:gsub("^|+%s*", "")
    elseif firstChar == "/" then
        emote = action:gsub("^/+%s*", "")
    elseif firstChar == "\\" then
        emote = action:gsub("^\\+%s*", "")
    -- elseif action:sub(1, 1) == "+" then
    --     emote = action:gsub("^%+%s*", "")
    elseif action:match("^l+ ") then
        emote = action:gsub("^l+%s+", "")
    end

    emote = UnderlineAsterisks(emote)

    if Settings.options.areEmotesContrasted then
        local myName = Turbine.Gameplay.LocalPlayer:GetInstance():GetName()
        if name == Emote.currEmoter or
          (name == "You" and Emote.currEmoter == myName) or
          (name == myName and Emote.currEmoter == "You") then
            emote = AddRgb(emote, self:getLightOrDark())
        else
            Emote.currEmoter = name
            Emote.isCurrColorLight = not Emote.isCurrColorLight
            emote = AddRgb(emote, self:getLightOrDark())
        end
        -- print(Emote.currEmoter)
    end

    return emote
end

    -- Optional features:
    -- Highlight player names and/or make them inspectable
    -- Line break between each post, or between different characters
    -- /clear

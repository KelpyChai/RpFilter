Emote = {
    MultiPosts = {}
}

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
        formattedEmote = formattedEmote:gsub("%*(..-)%*", "<u>%1</u>")
    end

    return formattedEmote
end

    -- Optional features:
    -- Highlight player names and/or make them inspectable
    -- Line break between each post, or between different characters
    -- /clear

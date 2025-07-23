Emote = {
    MultiPosts = {}
}

---Formats messages from the emote channel, including multi-post emotes
---@param message string
---@return string
function Emote:format(message)
    local name, _, emote = message:match("^(%a+(%-%d+)?) (.+)")
    local formattedEmote = message

    if emote:sub(1, 3) == "'s " then
        formattedEmote = name .. "'s " .. emote:gsub("^'s%s+", "")
    elseif emote:sub(1, 1) == "|" then
        formattedEmote = emote:gsub("^|+%s*", "")
    -- elseif emote:sub(1, 1) == "+" then
    --     formattedEmote = emote:gsub("^%+%s*", "")
    elseif emote:match("^l+ ") then
        formattedEmote = emote:gsub("^l+%s+", "")
    end

    return formattedEmote
end
-- Standard word characters extended with diacritics
WordChars = "A-Za-z0-9" ..
            "ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞß" ..
            "àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ"

---@param word string
---@return boolean
function IsCapitalized(word)
    return word:match("^'?[A-ZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞß]") ~= nil
end

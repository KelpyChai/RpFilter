function AddCallback(object, event, callback)
    if object[event] == nil then
        object[event] = callback
    elseif type(object[event]) == "table" then
        table.insert(object[event], callback)
    else
        object[event] = {object[event], callback}
    end
end

function RemoveCallback(object, event, callback)
    if object[event] == callback then
        object[event] = nil
    elseif type(object[event]) == "table" then
        local callbacks = object[event]
        for i = 1, #callbacks do
            if callbacks[i] == callback then
                table.remove(callbacks, i)
                break
            end
        end
    end
end

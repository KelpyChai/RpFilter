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
        for i = 1, #object[event] do
            if object[event][i] == callback then
                table.remove(object[event], i)
                break
            end
        end

        local size = #object[event]
        if size == 1 then
            object[event] = object[event][1]
        elseif size == 0 then
            object[event] = nil
        end
    end
end

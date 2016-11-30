
require 'threads'

local handlers = {}

local event = {}

function event.notify(name, data)
    local reg = handlers[name]
    if reg then
        for i,handler in ipairs(reg) do
            if false == handler(data, name, handler) then
                table.remove(reg, i)
            end
        end
    end
end

function event.listen(name, handler)
    if nil == handlers[name] then
        handlers[name] = { handler }
    else
        table.insert(handlers[name], handler)
    end
end

function event.ignore(name, handler)
    local reg = handlers[name]
    if reg then
        for i,h in ipairs(reg) do
            if h == handler then
                table.remove(reg, i)
                break
            end
        end
    end
end

return event

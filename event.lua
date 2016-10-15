
require 'threads'

local handlers = {}

function notify(name, data)
    local reg = handlers[name]
    if reg then
        for i,handler in ipairs(reg) do
            if false == handler(data, name, handler) then
                table.remove(reg, i)
            end
        end
    end
end

function listen(name, handler)
    if nil == handlers[name] then
        handlers[name] = { handler }
    else
        table.insert(handlers[name], handler)
    end
end

function ignore(name, handler)
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
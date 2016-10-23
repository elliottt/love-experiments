

function any(t, p)
    for _,x in pairs(t) do
        if p(x) then
            return true
        end
    end

    return false
end

function all(t, p)
    for _,x in pairs(t) do
        if not p(x) then
            return false
        end
    end

    return true
end

function filter(t, p)
    local res = {}
    for k,x in pairs(t) do
        if p(x) then
            if type(k) == 'number' then
                table.insert(res, x)
            else
                res[k] = x
            end
        end
    end

    return res
end



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

function math.round(n)
    local n, f = math.modf(n)

    if f > 0.5 then
        return n + 1
    elseif f < 0.5 then
        return n
    elseif n % 2 == 0 then
        return n
    else
        return n + 1
    end
end

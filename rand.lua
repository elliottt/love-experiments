

function choose(lo,hi)
    return love.math.random(lo,hi)
end

function flipCoin()
    return choose(0,1) == 1
end

-- pick a random element from an array
function pick(t)
    local ix = choose(1,#t)
    return t[ix]
end

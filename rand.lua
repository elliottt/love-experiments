

function choose(lo,hi)
    return love.math.random(lo,hi)
end

function flipCoin()
    return choose(0,1) == 1
end

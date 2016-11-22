
-- Iterator for points on the line between (x0,y0) and (x1,y1).
local function bresenham(x0, y0, x1, y1, radius, step)

    local mkPoint
    if math.abs(y1 - y0) > math.abs(x1 - x0) then
        x0, y0 = y0, x0
        x1, y1 = y1, x1

        mkPoint = function(x,y)
            return y,x
        end
    else
        mkPoint = function(x,y)
            return x,y
        end
    end

    -- if a radius and step were given, modify mkPoint to keep track of how far
    -- along the line we are.
    if radius ~= nil and step ~= nil then
        local oldMkPoint = mkPoint
        local inc = 0
        mkPoint = function(x,y)
            if inc > radius then
                return nil
            else
                inc = inc + step
                return oldMkPoint(x,y)
            end
        end
    end

    local deltax = math.abs(x1 - x0)
    local deltay = math.floor(math.abs(y1 - y0))
    local err    = math.floor(deltax / 2)

    local ystep
    if y0 < y1 then
        ystep = 1
    else
        ystep = -1
    end

    local x, y = x0, y0
    local xe, xstep
    if x0 < x1 then
        xstep = 1
        xe    = x1 + 1
    else
        xstep = -1
        xe    = x1 - 1
    end

    return function()
        if x == xe then
            return nil
        end

        local rx, ry = x, y

        x   = x + xstep
        err = err - deltay
        if err < 0 then
            y   = y   + ystep
            err = err + math.abs(deltax)
        end

        return mkPoint(rx,ry)
    end
end


local function fov(x0,y0,radius)
    local r = radius - 1

    local xl, xr = x0 - r, x0 + r
    local yt, yb = y0 - r, y0 + r
    local x,  y  = xl, yt

    local state, top, right, bottom, left
    local tx, ty

    function ret(a,b)
        local step

        local denom = b - y0
        if denom == 0 then
            step = 1
        else
            local slope = math.abs ((a - x0) / denom)
            if slope > 1 then
                step = 1 + (1 / slope) * 0.42
            else
                step = 1 + slope * 0.42
            end
        end

        return bresenham(x0,y0,a,b,radius,step), a, b, step
    end

    function top()
        if x < xr then
            tx = x
            x  = x + 1
            return ret(tx,y)
        else
            state = right
            return right()
        end
    end

    function right()
        if y < yb then
            ty = y
            y  = y + 1
            return ret(x,ty)
        else
            state = bottom
            return bottom()
        end
    end

    function bottom()
        if x > xl then
            tx = x
            x  = x - 1
            return ret(tx,y)
        else
            state = left
            return left()
        end
    end

    function left()
        if y > yt then
            ty = y
            y  = y - 1
            return ret(x,ty)
        else
            return nil
        end
    end

    state = top
    return function()
        return state()
    end

end

return {
    fov = fov,
    bresenham = bresenham,
}

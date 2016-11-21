
Pos = { x = 0, y = 0, kind = {} }

function Pos:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Pos:__tostring()
    return string.format('<Pos %d %d>', self:parts())
end

function Pos:__eq(other)
    return self.kind == other.kind and self.x == other.x and self.y == other.y
end

function Pos:hash()
    return bit.lshift(self.x,16) + self.y
end

function dist(x,y,a,b)
    local l = x - a
    local r = y - b
    return math.sqrt(l * l + r * r)
end

function Pos:dist(other)
    return dist(self.x, self.y, other.x, other.y)
end

function Pos.create(x,y)
    return Pos:new{ x=x, y=y }
end

function Pos:parts()
    return self.x, self.y
end

function Pos:moveNorth()
    return Pos.create(self.x, self.y - 1)
end

function Pos:moveEast()
    return Pos.create(self.x + 1, self.y)
end

function Pos:moveSouth()
    return Pos.create(self.x, self.y + 1)
end

function Pos:moveWest()
    return Pos.create(self.x - 1, self.y)
end

function Pos:neighbors()
    return {
        Pos.create(self.x,   self.y-1),
        Pos.create(self.x+1, self.y  ),
        Pos.create(self.x,   self.y+1),
        Pos.create(self.x-1, self.y  ),
    }
end

function Pos:adjust(x,y)
    self.x = self.x + x
    self.y = self.y + y
    return self
end

function Pos.slope(a,b)
    local denom = b.x - a.x
    if denom == 0 then
        return 0
    else
        return (b.y - a.y) / denom
    end
end


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

function slope(x,y,a,b)
    local denom = a - x
    if denom == 0 then
        return nil
    else
        return (b - y) / denom
    end
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

function neighbors(x,y)
    return {
        Pos.create(x, y-1),
        Pos.create(x+1, y),
        Pos.create(x, y+1),
        Pos.create(x-1, y),
    }
end

function Pos:neighbors()
    return neighbors(self.x, self.y)
end

function Pos:adjust(x,y)
    self.x = self.x + x
    self.y = self.y + y
    return self
end

function Pos.slope(a,b)
    local slope = slope(a.x,a.y,b.x,b.y)
    if slope == nil then
        return 0
    else
        return slope
    end
end


Direction = { kind = {}, dx=0, dy=0 }

function Direction:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Direction:__call(pos)
    return Pos.create(pos.x + self.dx, pos.y + self.dy)
end

function Direction:__tostring()
    return self.name
end

North     = Direction:new{ name='North',     kind={}, dx= 0, dy=-1, cost=1    }
NorthEast = Direction:new{ name='NorthEast', kind={}, dx= 1, dy=-1, cost=1.42 }
East      = Direction:new{ name='East',      kind={}, dx= 1, dy= 0, cost=1    }
SouthEast = Direction:new{ name='SouthEast', kind={}, dx= 1, dy= 1, cost=1.42 }
South     = Direction:new{ name='South',     kind={}, dx= 0, dy= 1, cost=1    }
SouthWest = Direction:new{ name='SouthWest', kind={}, dx=-1, dy= 1, cost=1.42 }
West      = Direction:new{ name='West',      kind={}, dx=-1, dy= 0, cost=1    }
NorthWest = Direction:new{ name='NorthWest', kind={}, dx=-1, dy=-1, cost=1.42 }

Direction.perpendicular = {
    { North, East,  NorthEast },
    { East,  South, SouthEast },
    { South, West,  SouthWest },
    { West,  North, NorthWest },
}

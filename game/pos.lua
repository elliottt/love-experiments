
Pos = { x = 0, y = 0, kind = {} }

function Pos:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Pos.create(x,y)
    return Pos:new{ x=x, y=y }
end

function Pos:parts()
    return self.x, self.y
end

function Pos:moveNorth()
    return Pos.new{ x = self.x, y = self.y - 1 }
end

function Pos:moveEast()
    return Pos.new{ x = self.x + 1, y = self.y }
end

function Pos:moveSouth()
    return Pos.new{ x = self.x, y = self.y + 1 }
end

function Pos:moveWest()
    return Pos.new{ x = self.x - 1, y = self.y }
end

function Pos:neighbors()
    return {
        Pos:new{ x = self.x,   y = self.y-1},
        Pos:new{ x = self.x+1, y = self.y  },
        Pos:new{ x = self.x,   y = self.y+1},
        Pos:new{ x = self.x-1, y = self.y  },
    }
end

function Pos:adjust(x,y)
    self.x = self.x + x
    self.y = self.y + y
    return self
end

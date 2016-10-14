
require 'game.pos'
require 'game.entity'
require 'game.prop'
require 'game.item'


Cell = {
    prop   = nil,
    entity = nil,
    item   = nil,
    kind   = nil,
}

function Cell:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Cell:passable()
    return true
end

function Cell:setEntity(new)
    local old = self.entity
    self.entity = new
    return old
end

function Cell:setProp(new)
    local old = self.prop
    self.prop = new
    return old
end

Wall = Cell:new{ kind = {} }

function Wall:passable()
    return false
end

Floor = Cell:new{ kind = {} }

Door = Cell:new{ kind = {} }



Map = {
    width = 0,
    height = 0,
    cells = nil,
}

function Map:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Map.create(width,height)
    local map = Map:new{
        width = width,
        height = height,
        size = width * height,
        cells = {},
    }

    for i=1,map.size do
        if i <= width or i % width == 0 or (i-1) % width == 0 or i > width * (height - 1) then
            table.insert(map.cells, Wall:new())
        else
            table.insert(map.cells, Floor:new())
        end
    end

    map:get(4,5):setProp(Chest.create())

    return map
end

-- Index into the map with 0-based coordinates.
--
-- If the second argument is nil, it's assumed that the first argument is a Pos.
function Map:get(x,y)
    if y == nil then
        return self.cells[x.y * self.width + x.x + 1]
    else
        return self.cells[y * self.width + x + 1]
    end
end

-- True when the position is within the bounds of the map
function Map:inBounds(pos)
    return pos.x >= 0 and pos.x < self.width
        and pos.y >= 0 and pos.y < self.height
end

-- An iterator for each cell of the map.
function Map:rows()
    local i   =  0
    local row = -1
    local col = -1
    return function()
        row = row + 1

        if row >= self.height then
            return nil
        else
            return row, function()
                col = col + 1

                if col >= self.width then
                    col = -1
                    return nil
                else
                    i = i + 1
                    return col, self.cells[i]
                end
            end
        end
    end
end

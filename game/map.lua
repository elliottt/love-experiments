
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

    return map
end

-- Index into the map with 0-based row/col pairs.
function Map:get(row,col)
    return self.cells[row * self.width + col + 1]
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

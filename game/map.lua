
require 'game.entity'
require 'game.prop'
require 'game.item'


Cell = {
    prop   = nil,
    entity = nil,
    item   = nil,
}

function Cell:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

Wall = Cell:new()

Floor = Cell:new()

Door = Cell:new()



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
        cells = {},
    }

    for i=1,width*height do
        table.insert(map.cells, Cell:new())
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
                i   = i   + 1
                col = col + 1

                if col >= self.width then
                    col = -1
                    return nil
                else
                    return col, self.cells[i]
                end
            end
        end
    end
end

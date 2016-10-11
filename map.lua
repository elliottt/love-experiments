
require 'entity'
require 'prop'
require 'item'


Cell = {}
Cell.__index = Cell

-- Construct a new cell.
function Cell.new(passable)
    local self = setmetatable({}, Cell)

    self.entity  = nil
    self.prop    = nil
    self.item    = nil
    self.terrain = terrain

    return self
end


Map = {}
Map.__index = Map

function Map.new(width,height)
    local self = setmetatable({}, Map)

    self.width  = width
    self.height = height
    self.cells  = {}

    for i in range(1,width*height) do
        table.insert(self.cells, Cell.new())
    end

    return self
end

-- Index into the map with 0-based row/col pairs.
function Map.get(self,row,col)
    return self.cells[row * self.width + col + 1]
end

-- An iterator for each cell of the map.
function Map.each(self)
    local i   =  0
    local row = -1
    local col =  0
    return function()
        i = i + 1

        if row >= self.width then
            row = 0
            col = col + 1
        end

        return row, col, self.cells[i]
    end
end

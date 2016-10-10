
Cell = {}
Cell.__index = Cell

-- Construct a new cell.
function Cell.new()
    local self = setmetatable({}, Cell)

    self.passable = true

    return self
end


Map = {}
Map.__index = Map

function Map.new(width,height)
    local self = setmetatable({}, Map)

    self.width  = width
    self.height = height

    for i in range(1,width) do
    end

    return self
end


function Map.get(row,col)
    return self.cells[row][col]
end

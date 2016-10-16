
require 'game.pos'
require 'game.entity'
require 'game.prop'
require 'game.item'


Cell = {
    prop   = nil,
    entity = nil,
    items  = nil,
    kind   = nil,
}

function Cell:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.items = {}
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

function Cell:addItem(item)
    table.insert(self.items, item)
end

function Cell:removeItem(item)
    for i,e in ipairs(self.items) do
        if e == item then
            table.remove(self.items, i)
            return
        end
    end
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

function Map.defaults(opts)
    opts                 = opts or {}
    opts.width           = opts.width or 128
    opts.height          = opts.height or 128
    opts.depth           = opts.depth or 1
    opts.startRoomWidth  = opts.startRoomWidth or 10
    opts.startRoomHeight = opts.startRoomHeight or 10
    return opts
end

function Map.create(opts)
    opts = Map.defaults(opts)
    local map = Map:new{
        width = opts.width,
        height = opts.height,
        size = opts.width * opts.height,
        cells = {},
        entrance = nil,
    }

    for i=1,map.size do
        table.insert(map.cells, Wall:new())
    end

    map:gen(opts)

    return map
end

function Map:ix(x,y)
    if y == nil then
        return x.y * self.width + x.x + 1
    else
        return y * self.width + x + 1
    end
end

-- Index into the map with 0-based coordinates.
--
-- If the second argument is nil, it's assumed that the first argument is a Pos.
function Map:get(x,y)
    return self.cells[self:ix(x,y)]
end

function Map:set(x,y,c)
    if c == nil then
        self.cells[self:ix(x)] = y
    else
        self.cells[self:ix(x,y)] = c
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


-- Map generator core
function Map:gen(opts)
    local entrance = RectRoom.create(0,0,
            love.math.random(6,opts.startRoomWidth),
            love.math.random(6,opts.startRoomHeight))


    entrance:apply(self)

    -- pick a point in the room to be an entrance
    self.entrance = entrance:pick()
    self:get(self.entrance):setProp(UpStairs:new())
end

Room = { kind = {} }

function Room:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

RectRoom = Room:new{ kind = {} }

function RectRoom.create(x, y, w, h)
    return RectRoom:new{
        x = x,
        y = y,
        w = w,
        h = h,
    }
end

function RectRoom:apply(map)
    for j=self.y+1,self.y + self.h-2 do
        for i=self.x+1,self.x + self.w-2 do
            map:set(i,j,Floor:new())
        end
    end
end

function RectRoom:pick()
    local x = love.math.random(self.x+1, self.x + self.w - 2)
    local y = love.math.random(self.y+1, self.y + self.h - 2)
    return Pos:new{ x=x, y=y }
end


require 'game.pos'
require 'game.entity'
require 'game.prop'
require 'game.item'
require 'game.bsp'
require 'game.grid'
require 'rand'


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

function Cell:vacant()
    return self:passable() and self.entity == nil
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
Hall  = Cell:new{ kind = {} }

Door = Cell:new{ kind = {} }


Map = Grid:new{ kind = {} }

function Map.defaults(opts)
    opts                 = opts or {}
    opts.width           = opts.width or 128
    opts.height          = opts.height or 128
    opts.depth           = opts.depth or 1
    opts.startRoomWidth  = opts.startRoomWidth  or 10
    opts.startRoomHeight = opts.startRoomHeight or 10
    opts.placeTries      = opts.placeTries or 10

    opts.maxIters        = opts.maxIters or 8
    -- percent chance of early termination during room generation
    opts.earlyExit       = opts.earlyExit or 10
    opts.numEarlyExits   = opts.numEarlyExits or 6

    opts.minRegionWidth  = opts.minRegionWidth or 5
    opts.minRegionHeight = opts.minRegionHeight or 5
    opts.minSplitWidth   = opts.minRegionWidth * 2 + 1
    opts.minSplitHeight  = opts.minRegionHeight * 2 + 1

    -- chance of filling an entire region with a room
    opts.bigRoomChance   = opts.bigRoomChance or 10

    opts.maxRoomWidth    = opts.maxRoomWidth or 10
    opts.maxRoomHeight   = opts.maxRoomHeight or 10

    -- minimum hallway length for two doors
    opts.hallwayDoorLen  = 4

    return opts
end

function Map.create(opts)
    opts = Map.defaults(opts)
    local map = Map:new{
        entrance = nil,
        depth = opts.depth,
        rooms = {},
    }:init(opts.width, opts.height, function() return Wall:new() end)

    map:gen(opts)

    return map
end


-- Map generator core
function Map:gen(opts)
    local bsp = self:divide(opts)
    self:placeRooms(opts,bsp)

    -- pick the first generated room as the entrance
    local entrance = self.rooms[1]
    entrance:apply(self)

    -- pick a point in the room to be an entrance
    self.entrance = entrance:pick()
    self:get(self.entrance):setProp(UpStairs:new())
end


-- Generate a BSP tree for the map.
function Map:divide(opts)
    return subDivide(opts, 0, Region.create(1,1,self.w-2,self.h-2))
end


-- Sub-divide a region. If the region isn't big enough to sub-divide, return it.
function subDivide(opts, iters, region)
    local horiz = region:splitHoriz(choose(
                  opts.minRegionHeight,
                  region.h - opts.minRegionHeight - 1))

    local vert  = region:splitVert(choose(
                  opts.minRegionWidth,
                  region.w - opts.minRegionWidth - 1))

    if iters >= opts.maxIters or
        (opts.numEarlyExits > 0 and choose(1,100) <= opts.earlyExit) then
        opts.numEarlyExits = opts.numEarlyExits - 1
        return region
    end

    if region.w < opts.minSplitWidth then
        if region.h < opts.minSplitHeight then
            return region
        else
            horiz.left  = subDivide(opts, iters+1, horiz.left)
            horiz.right = subDivide(opts, iters+1, horiz.right)
            return horiz
        end
    elseif region.h < opts.minSplitHeight then
        vert.left  = subDivide(opts, iters+1, vert.left)
        vert.right = subDivide(opts, iters+1, vert.right)
        return vert
    else
        if flipCoin() then
            vert.left  = subDivide(opts, iters+1, vert.left)
            vert.right = subDivide(opts, iters+1, vert.right)
            return vert
        else
            horiz.left  = subDivide(opts, iters+1, horiz.left)
            horiz.right = subDivide(opts, iters+1, horiz.right)
            return horiz
        end
    end

end


function Map:placeRooms(opts,node)
    if node.kind == Region.kind then
        self:placeRoom(opts, node)
    else
        self:placeRooms(opts, node.left)
        self:placeRooms(opts, node.right)

        if node.isVert then
            self:placeHorizHallway(opts, node.left, node.right)
        else
            self:placeVertHallway(opts, node.left, node.right)
        end
    end
end


function Map:addRoom(room)
    room:apply(self)
    table.insert(self.rooms, room)
end

-- Generate a room in this region.
function Map:placeRoom(opts, region)
    local w
    local h
    if choose(1,100) <= opts.bigRoomChance then
        w = region.w
        h = region.h
    else
        w = choose(opts.minRegionWidth, math.min(region.w, opts.maxRoomWidth))
        h = choose(opts.minRegionHeight, math.min(region.h, opts.maxRoomHeight))
    end

    local room = RectRoom.create(
        choose(region.x, region.x + (region.w - w)),
        choose(region.y, region.y + (region.h - h)),
        w, h
    )

    region.room = room

    self:addRoom(room)

    return room
end


function vertExtent(bsp)
    local l,h = bsp.y + bsp.h, bsp.y
    bsp:rooms(function(room)
        if room.y < l then
            l = room.y
        end

        local y = room.y + room.h - 1
        if y > h then
            h = y
        end
    end)

    return l,h
end


function Map:placeHorizHallway(opts, left, right)
    -- discover the hollow extent of each region
    local ll,lh = vertExtent(left)
    local rl,rh = vertExtent(right)

    -- find the region where the two extents overlap
    local l = math.max(ll,rl)
    local h = math.min(lh,rh)
    local y = choose(l+1,h-1)

    -- walk out along the x-axis from the split point in both directions, until
    -- a room is encountered
    local lx = right.x - 1
    local rx = lx
    while lx > left.x do
        if self:get(lx,y).kind ~= Wall.kind then
            lx = lx + 1
            break
        else
            lx = lx - 1
        end
    end

    local rb = right.x + right.w - 1
    while rx < rb do
        if self:get(rx,y).kind ~= Wall.kind then
            rx = rx - 1
            break
        else
            rx = rx + 1
        end
    end

    -- draw a room for the hallway
    local w    = rx - lx + 1
    local room = Hallway.create(lx,y,w,1)
    if self:validDoor(lx,y) then
        room:set(0,0,Door:new())
    end

    if w >= opts.hallwayDoorLen and self:validDoor(lx+w-1,y) then
        room:set(w-1,0,Door:new())
    end
    self:addRoom(room)
end


function horizExtent(bsp)
    local l,h = bsp.x + bsp.w, bsp.x
    bsp:rooms(function(room)
        if room.x < l then
            l = room.x
        end

        local x = room.x + room.w - 1
        if x > h then
            h = x
        end
    end)

    return l,h
end

function Map:placeVertHallway(opts, top, bottom)
    -- discover the hollow extent of each region
    local ll,lh = horizExtent(top)
    local rl,rh = horizExtent(bottom)

    -- find the region where the two extents overlap
    local l = math.max(ll,rl)
    local h = math.min(lh,rh)
    local x = choose(l+1,h-1)

    -- walk out along the x-axis from the split point in both directions, until
    -- a room is encountered
    local ly = bottom.y - 1
    local ry = ly
    while ly > top.y do
        if self:get(x,ly).kind ~= Wall.kind then
            ly = ly + 1
            break
        else
            ly = ly - 1
        end
    end

    local rb = bottom.y + bottom.h - 1
    while ry < rb do
        if self:get(x,ry).kind ~= Wall.kind then
            ry = ry - 1
            break
        else
            ry = ry + 1
        end
    end

    -- draw a room for the hallway
    local h = ry - ly + 1
    local room = Hallway.create(x,ly,1,h)
    if self:validDoor(x,ly) then
        room:set(0,0,Door:new())
    end

    if h >= opts.hallwayDoorLen and self:validDoor(x,ly+h-1) then
        room:set(0,h-1,Door:new())
    end
    self:addRoom(room)
end


function any(table,p)
    for _,x in pairs(table) do
        if p(x) then
            return true
        end
    end
    return false
end


function Map:neighbors(x,y)
    return {
        self:get(x,y-1),
        self:get(x+1,y),
        self:get(x,y+1),
        self:get(x-1,y),
    }
end


-- The assumption is that this is checking for placement before the hall has
-- been blitted into the map. As such, it assumes that the there should be solid
-- wall where the hallway would be.
function Map:validDoor(x,y)
    local passable = 0
    for _,cell in pairs(self:neighbors(x,y)) do
        if cell:passable() then
            passable = passable + 1
        end
        if passable > 2 or cell.kind == Hall.kind or cell.kind == Door.kind then
            return false
        end
    end
    return true
end


RectRoom = Grid:new{ kind = {} }

function RectRoom.create(x, y, w, h)
    return RectRoom:new{
        x=x,
        y=y
    }:init(w,h,function() return Floor:new() end)
end

function RectRoom:apply(map)
    self:blit{ dest=map }
end

function RectRoom:pick()
    local x = choose(self.x, self.x + self.w - 1)
    local y = choose(self.y, self.y + self.h - 1)
    return Pos:new{ x=x, y=y }
end


Hallway = RectRoom:new{ kind = {} }

function Hallway.create(x,y,w,h)
    return Hallway:new{ x=x, y=y }:init(w,h,function()
        return Hall:new()
    end)
end

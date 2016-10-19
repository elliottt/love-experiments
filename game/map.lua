
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

    opts.minRegionWidth  = opts.minRegionWidth or 5
    opts.minRegionHeight = opts.minRegionHeight or 5
    opts.minSplitWidth   = opts.minRegionWidth * 2 + 1
    opts.minSplitHeight  = opts.minRegionHeight * 2 + 1

    opts.maxRoomWidth    = opts.maxRoomWidth or 10
    opts.maxRoomHeight   = opts.maxRoomHeight or 10

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
    self:placeHallways(bsp)

    -- pick the first generated room as the entrance
    local entrance = self.rooms[1]
    entrance:apply(self)

    -- pick a point in the room to be an entrance
    self.entrance = entrance:pick()
    self:get(self.entrance):setProp(UpStairs:new())
end


-- Generate a BSP tree for the map.
function Map:divide(opts)
    return self:subDivide(opts, 0, Region.create(1,1,self.w-2,self.h-2))
end


-- Sub-divide a region. If the region isn't big enough to sub-divide, return it.
function Map:subDivide(opts, iters, region)
    local horiz = region:splitHoriz(choose(
                  opts.minRegionHeight,
                  region.h - opts.minRegionHeight - 1))

    local vert  = region:splitVert(choose(
                  opts.minRegionWidth,
                  region.w - opts.minRegionWidth - 1))

    if iters >= opts.maxIters then
        self:placeRoom(opts, region)
        return region
    end

    if region.w < opts.minSplitWidth then
        if region.h < opts.minSplitHeight then
            self:placeRoom(opts, region)
            return region
        else
            horiz.left  = self:subDivide(opts, iters+1, horiz.left)
            horiz.right = self:subDivide(opts, iters+1, horiz.right)
            return horiz
        end
    elseif region.h < opts.minSplitHeight then
        vert.left  = self:subDivide(opts, iters+1, vert.left)
        vert.right = self:subDivide(opts, iters+1, vert.right)
        return vert
    else
        if flipCoin() then
            vert.left  = self:subDivide(opts, iters+1, vert.left)
            vert.right = self:subDivide(opts, iters+1, vert.right)
            return vert
        else
            horiz.left  = self:subDivide(opts, iters+1, horiz.left)
            horiz.right = self:subDivide(opts, iters+1, horiz.right)
            return horiz
        end
    end

end


-- Generate a room in this region.
function Map:placeRoom(opts, region)
    local w = choose(opts.minRegionWidth, math.min(region.w, opts.maxRoomWidth))
    local h = choose(opts.minRegionHeight, math.min(region.h, opts.maxRoomHeight))
    local room = RectRoom.create(
        choose(region.x, region.x + (region.w - w)),
        choose(region.y, region.y + (region.h - h)),
        w, h
    )

    region.room = room

    room:apply(self)
    table.insert(self.rooms, room)
end

function Map:placeHallways(bsp)
    if bsp.kind == Node.kind then
        if bsp.left.kind == Region.kind and bsp.right.kind == Region.kind then
            if bsp.isVert then
                -- if the cut is vertical, the hallway is horizontal
                self:placeHorizHallway(bsp.left.room, bsp.right.room)
            else
                self:placeVertHallway(bsp.left.room, bsp.right.room)
            end
        else
            self:placeHallways(bsp.left)
            self:placeHallways(bsp.right)
        end
    else
        return
    end
end

-- INVARIANT: room1 is always above room2.
function Map:placeVertHallway(room1, room2)
    local l = math.max(room1.x, room2.x)
    local r = math.min(room1.x+room1.w, room2.x+room2.w) - 1
    local x = choose(l,r)
    local room = RectRoom.create(x, room1.y+room1.h, 1, room2.y-(room1.y+room1.h))
    room:set(0, 0, Door:new())
    if room.h > 1 then
        room:set(0, room.h-1, Door:new())
    end
    room:apply(self)
    table.insert(self.rooms, room)
end

-- INVARIANT: room1 is always left of room2.
function Map:placeHorizHallway(room1, room2)
    local l = math.max(room1.y, room2.y)
    local r = math.min(room1.y+room1.h, room2.y+room2.h) - 1
    local y = choose(l,r)
    local room = RectRoom.create(room1.x+room1.w, y, room2.x-(room1.x+room1.w), 1)
    room:set(0, 0, Door:new())
    if room.w > 1 then
        room:set(room.w-1, 0, Door:new())
    end
    room:apply(self)
    table.insert(self.rooms, room)
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

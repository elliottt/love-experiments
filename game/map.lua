
require 'game.pos'
require 'game.entity'
require 'game.prop'
require 'game.item'
require 'game.bsp'
require 'game.grid'
require 'rand'

local Set    = require 'containers.set'
local Graph  = require 'containers.graph'
local fov    = require 'game.fov'
local search = require 'search'


Cell = {
    prop   = nil,
    entity = nil,
    items  = nil,
    kind   = nil,
    light  = 0.0,
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

function Cell:blocksLight()
    return false
end

function Cell:passable()
    return true
end

function Cell:setEntity(new)
    local old = self.entity
    if old then
        self:exit(old)
    end

    self.entity = new
    if new then
        self:enter(new)
    end

    return old
end

-- called when an entity enters the cell
function Cell:enter(entity)
end

function Cell:exit(entity)
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

function Wall.create()
    return Wall:new{ light = 0.0 }
end

function Wall:passable()
    return false
end

function Wall:blocksLight()
    return true
end

Floor = Cell:new{ kind = {} }

function Floor.create()
    return Floor:new{}
end

Hall  = Cell:new{ kind = {} }

function Hall.create()
    return Hall:new{}
end

Door = Cell:new{ kind = {} }

function Door.create()
    return Door:new{
        open   = false,
        locked = false,
    }
end

function Door:enter()
    self.open = true
end

function Door:exit()
    self.open = false
end

function Door:blocksLight()
    return not self.open
end

function Door:passable()
    return not self.locked
end

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

    -- depth to stop generating multiple hallways at
    opts.hallwayThreshold = 3

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
        halls = {},
    }:init(opts.width, opts.height, function() return Wall.create() end)

    map:gen(opts)

    return map
end


-- Map generator core
function Map:gen(opts)
    local bsp = self:divide(opts)
    self:placeRooms(opts,1,bsp)

    -- pick a rooms for the entrance and exit
    local entrance = pick(self.rooms)

    local exit
    repeat
        exit = pick(self.rooms)
    until (exit ~= entrance or #self.rooms <= 1)

    -- pick a point for the stairs
    self.entrance = entrance:pick():adjust(entrance.x, entrance.y)
    self:get(self.entrance):setProp(UpStairs:new())

    -- pick a point for the down-stairs
    self.exit = exit:pick():adjust(exit.x, exit.y)
    self:get(self.exit):setProp(DownStairs:new())

    self:placeChests(opts)
end


function Map:placeChests(opts)
    local items, cell, x, y
    for i=1,2 do
        x, y, cell = self:pick(function(c)
            return c:vacant()
        end)

        -- TODO: generate some items
        cell.prop = Chest.create({})
    end
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
        (iters >= 1 and opts.numEarlyExits > 0 and choose(1,100) <= opts.earlyExit) then
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


function Map:placeRooms(opts,depth,node)
    if node.kind == Region.kind then
        self:placeRoom(opts, node)
    else
        self:placeRooms(opts, depth+1, node.left)
        self:placeRooms(opts, depth+1, node.right)

        if node.isVert then
            node.room = self:placeHorizHallway(opts, depth, node.left, node.right)
        else
            node.room = self:placeVertHallway(opts, depth, node.left, node.right)
        end
    end
end

function Map:addHall(hall)
    hall:apply(self)
    table.insert(self.halls, hall)
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


-- Return a sorted list of pairs of rooms that overlap.
function roomOverlap(mkExtent,distance,top,bottom)

    local ps = {}

    top:rooms(function(room1)
        local ai = mkExtent(room1)
        bottom:rooms(function(room2)
            local bi      = mkExtent(room2)
            local overlap = ai:overlaps(bi)
            if overlap ~= nil then
                table.insert(ps, {
                    overlap=overlap,
                    dist=distance(room1,room2),
                    room1=room1,
                    room2=room2,
                })
            end
        end)
    end)

    table.sort(ps, function(a,b)
        return a.dist < b.dist
    end)

    return ps

end


function Map:placeHorizHallway(opts, depth, left, right)
    local overlaps = roomOverlap(RectRoom.vertExtent,
            RectRoom.horizDistance, left, right)

    if #overlaps == 0 then
        error('TODO: handle non-overlap')
    end

    local rooms = {}
    local overlap, r1, r2, x, y, room
    for i=1, math.max(opts.hallwayThreshold-depth+1,1) do
        local e = overlaps[i]
        if e == nil then
            break
        end

        overlap, r1, r2 = e.overlap, e.room1, e.room2
        y = choose(overlap.l, overlap.h)
        x = r1.x + r1.w

        room = Hallway.create(x, y, r2.x-x, 1)

        self:chooseDoors(opts, room, room.w)
        self:addHall(room)

    end

    return rooms
end


function Map:placeVertHallway(opts, depth, top, bottom)
    local overlaps = roomOverlap(RectRoom.horizExtent,
            RectRoom.vertDistance, top, bottom)

    if #overlaps == 0 then
        error('TODO: handle non-overlap')
    end

    local rooms = {}
    local overlap, r1, r2, x, y, room
    for i=1, math.max(opts.hallwayThreshold-depth,1) do
        local e = overlaps[i]
        if e == nil then
            break
        end

        overlap, r1, r2 = e.overlap, e.room1, e.room2
        x = choose(overlap.l, overlap.h)
        y = r1.y + r1.h
        room = Hallway.create(x, y, 1, r2.y - y)

        self:chooseDoors(opts, room, room.h)
        self:addHall(room)
    end

    return rooms
end


-- Place doors at each end of a hallway.
function Map:chooseDoors(opts, room, len)

    if len >= opts.hallwayDoorLen then

        if self:validDoor(room.x, room.y) then
            room:set(0,0,Door.create())
        end

        if self:validDoor(room.r, room.b) then
            room:set(room.w-1, room.h-1, Door.create())
        end

    else

        local side = flipCoin()
        if side and self:validDoor(room.x, room.y) then
            room:set(0,0,Door.create())
        elseif self:validDoor(room.r, room.b) then
            room:set(room.w-1, room.h-1, Door.create())
        end

    end

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

function Map:passable(x,y)
    local cell = self:get(x,y)
    return cell ~= nil and cell:passable()
end


RectRoom = Grid:new{ kind = {} }

function RectRoom.create(x, y, w, h)
    return RectRoom:new{
        x=x,
        y=y,
        b=y+h-1, -- bottom
        r=x+w-1, -- right
    }:init(w,h,function() return Floor.create() end)
end

function RectRoom:horizDistance(other)
    if other.r < self.x then
        return self.x - other.r - 1
    else
        return other.x - self.r - 1
    end
end

function RectRoom:vertDistance(other)
    if other.b < self.y then
        return self.y - other.b - 1
    else
        return other.y - self.b - 1
    end

end

-- Return the padded interval that represents the vertical extent of the room.
function RectRoom:vertExtent()
    return Interval.create(self.y+1, self.y+self.h-2)
end

-- Return the padded interval that represents the vertical extent of the room.
function RectRoom:horizExtent()
    return Interval.create(self.x+1, self.x+self.w-2)
end

function RectRoom:apply(map)
    self:blit{ dest=map }
end

function RectRoom:pick()
    local x = choose(0, self.w-1)
    local y = choose(0, self.h-1)
    return Pos:new{ x=x, y=y }
end


Hallway = RectRoom:new{ kind = {} }

function Hallway.create(x,y,w,h)
    return Hallway:new{
        x=x,
        y=y,
        b=y+h-1, -- bottom
        r=x+w-1, -- right
    }:init(w,h,function() return Hall.create() end)
end



Interval = {}

function Interval:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function Interval.create(l,h)
    return Interval:new{l=l, h=h}
end

function Interval:overlaps(other)
    if not (self.l > other.h or self.h < other.l) then
        return Interval.create(math.max(self.l, other.l),
                math.min(self.h, other.h))
    else
        return nil
    end
end

function Interval:__tostring()
    return string.format('<Interval %d %d>', self.l, self.h)
end



Planner = { kind = {} }

function Planner:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Planner.create(map)
    return Planner:new{ map=map }:recache()
end

function Planner:recache()
    local map   = self.map
    local verts = Set.create(Pos.hash)

    local other1, other2

    -- for all blocked cells, find the vertices of the subgoal graph.
    local pos, a, b
    for y, row in map:rows() do
        for x, cell in row do
            if cell:passable() then
                pos = Pos.create(x,y)
                for _, c in next, Direction.perpendicular do
                    cell = map:get(c[3](pos))
                    if cell and not cell:passable() then
                        a = map:get(c[1](pos))
                        b = map:get(c[2](pos))
                        if a and b and a:passable() and b:passable() then
                            verts:insert(pos)
                        end
                    end
                end
            end
        end
    end

    self.verts = verts
    local graph = Graph.undirected(Pos.hash)

    for pos in verts:iter() do
        for s in self:getDirectHReachable(pos):iter() do
            graph:newEdge(pos, s, pos:dist(s), true)
        end
    end

    self.graph = graph

    return self
end

function Planner:isSubgoal(pos)
    return self.verts:member(pos)
end

function Planner:clearance(pos, dir)
    local i = 0
    local tmp
    while true do
        tmp = dir(pos)

        if not self.map:passable(tmp) then
            return i, pos
        end

        pos = tmp
        i   = i + 1

        if self:isSubgoal(pos) then
            return i, pos
        end
    end
end

function Planner:getDirectHReachable(pos)
    local S = Set.create(Pos.hash)

    local clearances = {}
    for _, d in next, Direction.all do
        local i, p = self:clearance(pos, d)
        clearances[d] = { value=i, pos=p }

        if self:isSubgoal(p) then
            S:insert(p)
        end
    end

    local outer, inner, max, diag, s, j, e
    for _, d in next, Direction.diagonal do
        outer = clearances[d]
        diag  = outer.value
        if self:isSubgoal(outer.pos) then
            diag = diag - 1
        end

        for _, c in next, d.cardinals do
            inner = clearances[c]

            max = inner.value
            if self:isSubgoal(inner.pos) then
                max = max - 1
            end

            s = pos
            for i=1,diag do
                s = d(s)
                j, e = self:clearance(s, c)
                if j <= max and self:isSubgoal(e) then
                    S:insert(e)
                    j = j - 1
                end

                if j < max then
                    max = j
                end
            end
        end
    end

    return S

end

-- Find a path between two positions.
--
-- @a Starting Pos
-- @b Ending Pos
--
-- @return a path between a and b, or nil if the path is blocked.
function Planner:findPath(a, b)
    if a == b then
        return nil
    end

    local path = self:tryDirectPath(a, b)
    if path then
        return path
    end

    local hpath = self:findAbstractPath(a,b)
    if hpath == nil then
        return nil
    end

    path = {a}
    local p1 = hpath[1]
    local p2
    local skip
    for i=2,#hpath do
        p2 = hpath[i]
        skip = true
        for x,y in fov.bresenham(p1.x, p1.y, p2.x, p2.y) do
            if not skip then
                table.insert(path, Pos.create(x,y))
            end
            skip = false
        end
        p1 = p2
    end

    return path
end

-- Returns an array of positions if there is a direct path between the two
-- points, otherwise nil is returned.
--
-- @a Starting Pos
-- @b Ending Pos
--
-- @return a path between a and b, or nil if the path is blocked.
function Planner:tryDirectPath(a, b)
    local path={}
    for x, y in fov.bresenham(a.x, a.y, b.x, b.y) do
        if self.map:passable(x,y) then
            table.insert(path, Pos.create(x,y))
        else
            return nil
        end
    end
    return path
end

function Planner:findAbstractPath(a, b)
    return self:connectToGraph(a, function()
        return self:connectToGraph(b, function()
            return search.astar(a, Pos.hash, function(p)
                return self.graph:outgoing(p)
            end,
            function(p)
                return b:dist(p)
            end)
        end)
    end)
end

function Planner:connectToGraph(pos, body)
    if self:isSubgoal(pos) then
        return body()
    else
        for s in self:getDirectHReachable(pos):iter() do
            self.graph:newEdge(pos, s, pos:dist(s))
        end
        local res = body()
        self.graph:removeNode(pos)
        return res
    end
end

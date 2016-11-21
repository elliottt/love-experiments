
require 'game.entity'
require 'game.map'
require 'utils'

search = require('search')


local function genSeed()
    return love.math.random(0, 2 ^ 54 - 1)
end

Model = {}

function Model:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Model.create(opts)
    opts = opts or {}
    local model = Model:new{
        player = Player:new{
            hp     = 15,
            max_hp = 15,
            pos    = Pos:new{x = 1, y = 1 },
            path   = nil,
        },
        mapWidth = opts.mapWidth or 128,
        mapHeight = opts.mapHeight or 128,
        levels = {},
        level = 0,
        current = nil,
        seed = opts.seed or genSeed(),
        turns = 0,
    }

    love.math.setRandomSeed(model.seed)

    model:enterLevel(1)

    return model
end

function Model:map()
    return self.current.map
end

-- Spawn a mob, dependent on current level.
function Model:spawn(pos)
    return self.current:spawn(pos)
end

function Model:ascend()
    return self:enterLevel(self.level - 1)
end

function Model:descend()
    return self:enterLevel(self.level + 1)
end

-- Generate a fresh level, or restore an already existing level.
function Model:enterLevel(depth)

    if depth <= 0 then
        return
    end

    if self.levels[depth] == nil then
        self.levels[depth] = Level.create{
            width = self.mapWidth,
            height = self.mapHeight,
            depth = depth,
        }
    end

    self.current = self.levels[depth]
    local map = self:map()

    -- if descending, place the player in the up-stairs
    local pos
    if self.level < depth then
        pos = map.entrance
    else
        pos = map.exit
    end


    self.level = depth

    self.player.pos = pos
    map:get(pos):setEntity(self.player)

    self.current:lightFov(pos)

    self.current:enterLevel()
end


function Model:takeStep(playerAction)
    playerAction()
    self.current:moveMobs(self)

    -- increment turn count
    self.turns = self.turns + 1

    -- consider spawning some new mobs
    if self.turns % 256 == 0 then
        self.level:spawn(self.level:findHidden())
    end

end


-- Returns either nil in the case that the move didn't trigger any action, or an
-- entity if it is to trigger an attack.
function Model:moveEntity(entity, newPos)
    local map = self:map()

    -- ignore invalid new positions
    if not map:inBounds(newPos) then
        return nil
    end

    local cell = map:get(newPos)

    -- ignore movement into a wall
    if not cell:passable() then
        return nil
    end

    -- ignore occupied cells
    if cell.entity ~= nil then
        return cell, cell.entity
    end

    local oldCell  = map:get(entity.pos)
    oldCell:setEntity(nil)
    cell:setEntity(entity)
    entity.pos     = newPos

    return nil
end

-- Apply a function to the player's position, likely one of the Pos:move*
-- functions.
function Model:movePlayer(by)
    return self:playerMove(by(self.player.pos))
end

function Model:playerMove(newPos)
    -- if the movement is succeessful or invalid, no cell is returned
    local cell, target = self:moveEntity(self.player, newPos)
    if cell == nil then
        self.player.path = nil
        self.current:lightFov(self.player.pos)
        return
    end

    -- something in the cell was blocking us
    if target == nil then
        cell:interact(self.player, self)
        return
    end

    -- otherwise, there is an attack to perform
    target.hp = target.hp - 1
    if target.hp == 0 then
        notify('dead', cell)
        self:kill(cell)
    end
end

-- Find a path from a to b, ignoring cells below a given light threshold.
function Model:findPath(a,b,threshold)
    local map = self:map()

    -- if the positions are the same, don't bother finding a path
    if a == b then
        return nil
    end

    -- if the target is already invisible, bail out early.
    if map:get(b).light < threshold then
        return nil
    end

    return search.astar(a,

        -- hash positions in the visited set
        function(p)
            return p:hash()
        end,

        -- filter out neighbors that aren't passable
        function(pos)
            return filter(pos:neighbors(), function(n)
                cell = map:get(n)
                return cell and cell:passable() and cell.light >= threshold
            end)
        end,

        -- distance from b to a
        function(pos)
            return b:dist(pos)
        end,

        500)
end

-- Choose the player's next step using A* towards the exit.
function Model:searchStep()

    if self.player.pos == self:map().exit then
        return
    end

    if self.player.path == nil then
        -- the player is only allowed to find paths that involve parts of the
        -- level that they have seen before.
        self.player.path = self:findPath(self.player.pos, self:map().exit, 0.5)

        -- the path includes the current position, so drop the first move
        if self.player.path then
            table.remove(self.player.path, 1)
        end
    end

    local move = nil
    if self.player.path and #self.player.path > 0 then
        move = table.remove(self.player.path, 1)
        self:playerMove(move)
    end

end

-- Make this entity within this cell dead
function Model:kill(cell)
    local entity = cell.entity
    if nil == entity then
        return
    end

    -- remove the entity from the cell and the mob list
    cell.entity = nil
    self:removeMob(entity)

    -- replace the entity with a corpse, and add the corpse to the cell's item
    -- list
    cell:addItem(Corpse:new())
end

function Model:removeMob(entity)
    self.current:removeMob(entity)
end

-- Interact the player with something
function Model:interact()
    local cell = self:map():get(self.player.pos)
    if cell.prop then
        cell.prop:interact(self.player, cell, self)
    end
end


Level = {}

function Level:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Level.create(opts)
    return Level:new{
        map  = Map.create(opts),
        mobs = {},
    }
end

function Level:enterLevel()
    for i=1,4 - #self.mobs do
        local pos = self:findHidden()
        if pos then
            self:spawn(pos)
        end
    end
end

function Level:lightFov(pos, radius)
    local map = self.map

    radius = radius or 6

    for _, cell in ipairs(map.cells) do
        if cell.light > 0 then
            cell.light = 0.7
        end
    end

    for ray in map:fov(pos, radius) do
        for x,y in ray do
            local cell = map:get(x,y)
            if cell == nil then
                break
            elseif dist(pos.x, pos.y, x, y) > radius then
                break
            elseif cell:blocksLight() then
                cell.light = 1.0
                break
            else
                cell.light = 1.0
            end
        end
    end

end

function Level:findHidden()
    local x, y, cell = self.map:pick(function(cell)
        return cell:passable() and cell.light <= 0.8
    end)

    if x ~= nil then
        return Pos.create(x,y), cell
    else
        return nil
    end
end

function Level:spawn(pos)
    local cell = self.map:get(pos)
    if cell.entity then
        return nil
    end

    local mob = Monster:new{ pos = pos, hp = 1, ai = Wander:new{} }
    table.insert(self.mobs, mob)
    cell:setEntity(mob)

    return mob
end

function Level:moveMobs(model)
    for _,mob in pairs(self.mobs) do
        mob:action(model)
    end

    return self
end

function Level:removeMob(entity)
    for i,mob in ipairs(self.mobs) do
        if mob == entity then
            table.remove(self.mobs, i)
            return
        end
    end
end

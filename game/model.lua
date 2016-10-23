
require 'game.entity'
require 'game.map'
require 'utils'


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
            pos    = Pos:new{x = 1, y = 1 }
        },
        mapWidth = opts.mapWidth or 128,
        mapHeight = opts.mapHeight or 128,
        mobs = {},
        levels = {},
        current = nil,
        seed = opts.seed or genSeed(),
    }

    love.math.setRandomSeed(model.seed)

    model:enterLevel(1)

    return model
end

function Model:map()
    return self.current
end

-- Spawn a mob, dependent on current level.
function Model:spawn(pos)
    local cell = self.current:get(pos)
    if cell.entity then
        return nil
    end

    local mob = Monster:new{ pos = pos, hp = 1, ai = Wander:new{} }
    table.insert(self.mobs, mob)
    cell:setEntity(mob)

    return mob
end

-- Generate a fresh level, or restore an already existing level.
function Model:enterLevel(depth)
    self.level = depth

    if self.levels[depth] == nil then
        self.levels[depth] = Map.create{
            width = self.mapWidth,
            height = self.mapHeight,
            depth = depth,
        }
    end

    self.current = self.levels[depth]
    local map = self.current

    -- place the player at the entrance to the level
    self.player.pos = map.entrance
    map:get(map.entrance):setEntity(self.player)
    self:spawn(Pos:new{ x = 3, y = 3 })
end


function Model:takeStep(playerAction)
    playerAction()
    self:moveMobs()
end


-- Returns either nil in the case that the move didn't trigger any action, or an
-- entity if it is to trigger an attack.
function Model:moveEntity(entity, newPos)
    -- ignore invalid new positions
    if not self.current:inBounds(newPos) then
        return nil
    end

    local cell = self.current:get(newPos)

    -- ignore movement into a wall
    if not cell:passable() then
        return nil
    end

    -- ignore occupied cells
    if cell.entity ~= nil then
        return cell, cell.entity
    end

    local oldCell  = self.current:get(entity.pos)
    oldCell.entity = nil
    cell.entity    = entity
    entity.pos     = newPos

    return nil
end

-- Apply a function to the player's position, likely one of the Pos:move*
-- functions.
function Model:movePlayer(by)
    local newPos = by(self.player.pos)

    -- if the movement is succeessful, no cell is returned
    local cell, target = self:moveEntity(self.player, newPos)
    if cell == nil then
        return
    end

    -- otherwise, there is an attack to perform
    target.hp = target.hp - 1
    if target.hp == 0 then
        notify('dead', cell)
        self:kill(cell)
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
    for i,mob in ipairs(self.mobs) do
        if mob == entity then
            table.remove(self.mobs, i)
            return
        end
    end
end

-- Interact the player with something
function Model:interact()
    local cell = self.current:get(self.player.pos)
    if cell.prop then
        cell.prop:interact(self.player)
    end
end


function Model:moveMobs()
    for _,mob in pairs(self.mobs) do
        mob:action(self)
    end
end


require 'game.entity'
require 'game.map'


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

    model:enterLevel(1)

    return model
end

function Model:map()
    return self.current
end

-- Generate a fresh level, or restore an already existing level.
function Model:enterLevel(depth)
    self.level = depth

    if self.levels[depth] == nil then
        self.levels[depth] = Map.create(self.mapWidth, self.mapHeight)
    end

    self.current = self.levels[depth]

    -- place the player
    self.current:get(self.player.pos):setEntity(self.player)
end

function Model:moveEntity(entity, newPos)
    -- ignore invalid new positions
    if not self.current:inBounds(newPos) then
        return false
    end

    local cell = self.current:get(newPos)

    -- ignore movement into a wall
    if not cell:passable() then
        return false
    end

    -- ignore occupied cells
    if cell.entity ~= nil then
        return false
    end

    local oldCell  = self.current:get(entity.pos)
    oldCell.entity = nil
    cell.entity    = entity
    entity.pos     = newPos

    return true
end

-- Apply a function to the player's position, likely one of the Pos:move*
-- functions.
function Model:movePlayer(by)
    local newPos = by(self.player.pos)

    -- if the movement is succeessful, return
    if self:moveEntity(self.player, newPos) then
        return
    end

end

-- Interact the player with something
function Model:interact()
    local cell = self.current:get(self.player.pos)
    if cell.prop then
        cell.prop:interact(self.player)
    end
end

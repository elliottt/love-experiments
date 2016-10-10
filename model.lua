
require 'map'

Pos = {}
Pos.__index = Pos

function Pos.new(x,y)
    local self = setmetatable({}, Pos)

    self.x = x
    self.y = y

    return self
end

function Pos.parts(self)
    return self.x, self.y
end

function Pos.moveNorth(self)
    return Pos.new(self.x,self.y - 1)
end

function Pos.moveEast(self)
    return Pos.new(self.x + 1, self.y)
end

function Pos.moveSouth(self)
    return Pos.new(self.x, self.y + 1)
end

function Pos.moveWest(self)
    return Pos.new(self.x - 1, self.y)
end


Character = {}
Character.__index = Character

function Character.new(max_hp, pos)
    local self = setmetatable({}, Character)

    self.max_hp = max_hp
    self.pos    = pos

    return self
end


Model = {}
Model.__index = Model

local function genSeed()
    return love.math.random(0, 2 ^ 54 - 1)
end

function Model.new()
    local self = setmetatable({}, Model)

    self.player = Character.new(15, Pos.new(0,0))
    self.mobs   = {}
    self.levels = {}
    self.seed   = genSeed()

    return self
end

-- Generate a fresh level, or restore an already existing level.
function Model.enterLevel(self, depth)
    if self.levels[depth] then
        return
    else
        self.levels[depth] = self.genLevel(depth)
    end
end

-- Generate a fresh level, for the given depth.
function Model.genLevel(self, depth)
    return {}
end

-- Apply a function to the player's position, likely one of the Pos:move*
-- functions.
function Model.movePlayer(self, by)
    local newPos = by(self.player.pos)

    -- XXX: interpret the movement

    self.player.pos = newPos
end

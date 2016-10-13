
require 'game.map'

Pos = { x = 0, y = 0 }

function Pos:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Pos:parts()
    return self.x, self.y
end

function Pos:moveNorth()
    return Pos.new{ x = self.x, y = self.y - 1 }
end

function Pos:moveEast()
    return Pos.new{ x = self.x + 1, y = self.y }
end

function Pos:moveSouth()
    return Pos.new{ x = self.x, y = self.y + 1 }
end

function Pos:moveWest()
    return Pos.new{ x = self.x - 1, y = self.y }
end


Character = {
    hp = 0,
    max_hp = 15,
}
Character.__index = Character

function Character:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


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
        player = Character:new{
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
end

-- Apply a function to the player's position, likely one of the Pos:move*
-- functions.
function Model:movePlayer(by)
    local newPos = by(self.player.pos)
    local cell   = self.current:get(newPos.x, newPos.y)

    if cell and cell:passable() then
        self.player.pos = newPos
    end
end

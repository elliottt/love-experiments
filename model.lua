
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
    self.y = self.y - 1
end

function Pos.moveEast(self)
    self.x = self.x + 1
end

function Pos.moveSouth(self)
    self.y = self.y + 1
end

function Pos.moveWest(self)
    self.x = self.x - 1
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

function Model.new()
    local self = setmetatable({}, Model)

    self.player = Character.new(15, Pos.new(0,0))
    self.mobs   = {}
    self.levels = {}

    return self
end

function Model.move(self, by)
    by(self.player.pos)
end

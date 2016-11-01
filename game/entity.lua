
require 'event'
require 'game.pos'

Entity = {
    kind = {},
}

function Entity:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.max_hp = o.max_hp or 10
    o.hp     = o.hp     or o.max_hp
    o.pos    = o.pos    or Pos:new{ x = 0, y = 0 }
    o.items  = o.items  or {}

    return o
end

Player  = Entity:new{ kind = {} }
Monster = Entity:new{ kind = {} }

function Monster:action(model)
    if self.ai then
        self.ai:action(self, model)
    end
end



AI = {}

function AI:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function AI:action(model)
end


Wander = AI:new{ kind = {} }

function Wander:action(entity, model)
    local ns = filter(entity.pos:neighbors(), function(pos)
        local cell = model:map():get(pos.x, pos.y)
        return cell ~= nil and cell:vacant()
    end)

    if #ns <= 0 then
        return
    end

    -- move in a random direction
    model:moveEntity(entity, pick(ns))
end

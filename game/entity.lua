
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

Player = Entity:new{ kind = {} }


require 'utils'
require 'event'
require 'game.pos'

local fov = require 'game.fov'

Entity = {
    kind = {},
}

function Entity:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.max_hp   = o.max_hp or 10
    o.hp       = o.hp     or o.max_hp
    o.pos      = o.pos    or Pos.create(0,0)
    o.items    = o.items  or {}
    o.equipped = o.equipped or {}

    return o
end

function Entity:equip(item)
    -- if the item can't be equipped
    if not item:equippable() then
        return false
    end

    -- if something of that kind is already equipped
    if self.equipped[item.kind] ~= nil then
        return false
    end

    -- equip it
    self.equipped[item.kind] = item

    return true
end

Player  = Entity:new{ kind = {} }
Monster = Entity:new{ kind = {} }

function Monster:action(model)
    if self.ai then
        local new = self.ai:action(self, model)
        if new ~= nil then
            self.ai = new
        end
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

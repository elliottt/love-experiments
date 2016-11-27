
Item = { kind = {} }

function Item:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Item:equippable()
    return false
end

function Item.__lt(a,b)

end


Corpse = Item:new{ kind = {} }

function Corpse.create(items)
    return Corpse:new{ items=items }
end


-- Armor kinds
Armor = Item:new{ kind = {} }

function Armor:equippable()
    return true
end

Head   = Armor:new{ kind = {} }
Hands  = Armor:new{ kind = {} }
Feet   = Armor:new{ kind = {} }
Torso  = Armor:new{ kind = {} }
Legs   = Armor:new{ kind = {} }


-- Weapons kinds
Weapon = Item:new{ kind = {} }

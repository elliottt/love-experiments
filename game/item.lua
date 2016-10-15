
Item = { kind = {} }

function Item:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

Corpse = Item:new{ kind = {} }

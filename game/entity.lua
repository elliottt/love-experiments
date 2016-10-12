
Entity = {
    hp     = 15,
    max_hp = 15
}

function Entity:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

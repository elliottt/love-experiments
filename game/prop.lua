
Prop = {
    kind = {},
}

function Prop:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function Prop:interact(player)
end


Chest = Prop:new{ kind = {} }

function Chest.create()
    return Chest:new{
        contents = {},
        locked = false,
        open = false,
    }
end

function Chest:interact(player)
    self.open = not self.open
end

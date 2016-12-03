
local event = require 'event'

Prop = {
    kind = {},
}

function Prop:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function Prop:interact(player, cell, model)
end


Chest = Prop:new{ kind = {} }

function Chest.create(contents)
    return Chest:new{
        contents = contents,
        locked = true,
        open = false,
    }
end

function Chest:interact(player, cell)
    if self.locked then
        event.notify('prop.chest.unlock', cell)
    end

    self.open = not self.open
end


UpStairs = Prop:new{ kind = {} }

function UpStairs:interact(player, cell, model)
    model:ascend()
end



DownStairs = Prop:new{ kind = {} }

function DownStairs:interact(player, cell, model)
    model:descend()
end

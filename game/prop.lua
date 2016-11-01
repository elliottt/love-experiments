
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
        locked = true,
        open = false,
    }
end

function Chest:interact(player, cell)
    if self.locked then
        notify('unlock', cell)
    end

    self.open = not self.open
end


UpStairs = Prop:new{ kind = {} }

function UpStairs:interact(player, cell)
    print('upstairs!')
end



DownStairs = Prop:new{ kind = {} }

function UpStairs:interact(player, cell)
    print('down stairs!')
end

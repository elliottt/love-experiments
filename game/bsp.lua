
require 'rand'

BSP = { kind = {} }

function BSP:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function BSP:contains(x,y)
    return self.x <= x and x < self.x + self.w
       and self.y <= y and y < self.y + self.h
end

function BSP:rooms()
end


Region = BSP:new{ kind = {} }

function Region:__tostring()
    return string.format('<Region %d %d %d %d %s>',
            self.x, self.y, self.w, self.h, self.full)
end

function Region.create(x,y,w,h)
    return Region:new{ x=x, y=y, w=w, h=h, full=false, room=nil }
end


function Region:lookup(x,y)
    if self:contains(x,y) then
        return self
    else
        return nil
    end
end

-- Cut a region in half, vertically. The parameter supplied is expected to be a
-- width relative to the current region.
function Region:splitVert(w)
    return Node.create(
        true, self.x, self.y, self.w, self.h,
        Region.create(self.x,         self.y,          w - 1, self.h),
        Region.create(self.x + w + 1, self.y, self.w - w - 1, self.h))
end

function Region:splitHoriz(h)
    return Node.create(
        false, self.x, self.y, self.w, self.h,
        Region.create(self.x, self.y,         self.w,          h - 1),
        Region.create(self.x, self.y + h + 1, self.w, self.h - h - 1))
end

-- Pick a random point within the region.
function Region:pick()
    return 
        choose(self.x, self.x + self.w - 1),
        choose(self.y, self.y + self.h - 1)
end

function Region:rooms(accumulate)
    if self.room ~= nil then
        accumulate(self.room)
    end
end


Node = BSP:new{ kind = {} }

function Node:__tostring()
    return string.format('<Node %dx%d %s %s>',
            self.w, self.h, self.left:__tostring(), self.right:__tostring())
end

function Node.create(isVert,x,y,w,h,left,right)
    return Node:new{ isVert=isVert, left=left, right=right, w=w, h=h, room=nil }
end

function Node:lookup(x,y)
    if self:contains(x,y) then
        local a = self.left:lookup(x,y)
        if a == nil then
            return self.right:lookup(x,y)
        else
            return a
        end
    else
        return nil
    end
end

function Node:rooms(accumulate)
    self.left:rooms(accumulate)
    if self.room ~= nil then
        accumulate(self.room)
    end
    self.right:rooms(accumulate)
end

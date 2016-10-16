
require 'rand'

BSP = { kind = {} }

function BSP:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


Region = BSP:new{ kind = {} }

function Region:__tostring()
    return string.format('<Region %d %d %d %d %s>',
            self.x, self.y, self.w, self.h, self.full)
end

function Region.create(x,y,w,h)
    return Region:new{ x=x, y=y, w=w, h=h, full=false }
end

-- Cut a region in half, vertically. The parameter supplied is expected to be a
-- width relative to the current region.
function Region:splitVert(w)
    return Node.create(
        Region.create(self.x,         self.y,          w - 1, self.h),
        Region.create(self.x + w + 1, self.y, self.w - w - 1, self.h),
        self.w,
        self.h)
end

function Region:splitHoriz(h)
    return Node.create(
        Region.create(self.x, self.y,         self.w,          h - 1),
        Region.create(self.x, self.y + h + 1, self.w, self.h - h - 1),
        self.w,
        self.h)
end

-- When a box of the given width and height would fit in this region, return the
-- region that could contain its top-left corner.
function Region:contains(w,h)
    if not self.full and self.w >= w and self.h >= h then
        return Region.create(self.x, self.y, self.w - w, self.h - h)
    else
        return nil
    end
end

-- Pick a random point within the region.
function Region:pick()
    return 
        choose(self.x, self.x + self.w - 1),
        choose(self.y, self.y + self.h - 1)
end


Node = BSP:new{ kind = {} }

function Node:__tostring()
    return string.format('<Node %dx%d %s %s>',
            self.w, self.h, self.left:__tostring(), self.right:__tostring())
end

function Node.create(left,right,w,h)
    return Node:new{ left=left, right=right, w=w, h=h }
end

-- Return either region that could contain the given box, or nil if neither
-- would fit. If either would fit, flip a coin to choose.
function Node:contains(w,h)
    if self.w < w or self.h < h then
        return nil
    end

    local left  = self.left:contains(w,h)
    local right = self.right:contains(w,h)

    if left ~= nil and right ~= nil then
        if love.math.random(0,1) == 0 then
            return left
        else
            return right
        end
    elseif left ~= nil then
        return left
    else
        return right
    end
end

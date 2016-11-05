
require 'game.pos'

Grid = { kind = {} }

function Grid:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Grid:init(w,h,z)
    self.x     = self.x or 0
    self.y     = self.y or 0
    self.w     = self.w or w
    self.h     = self.h or h
    self.size  = self.w * self.h
    self.cells = {}

    if type(z) == 'function' then
        for i=1,self.size do
            table.insert(self.cells, z())
        end
    else
        for i=1,self.size do
            table.insert(self.cells, z)
        end
    end

    return self
end

function Grid:inBounds(pos)
    return pos.x >= 0 and pos.x < self.w
        and pos.y >= 0 and pos.y < self.h
end

function Grid:get(x,y)
    if type(x) == 'number' then
        return self.cells[y * self.w + x + 1]
    else
        return self.cells[x.y * self.w + x.x + 1]
    end
end

function Grid:set(x,y,c)
    if type(x) == 'number' then
        self.cells[y * self.w + x + 1] = c
    else
        self.cells[x.y * self.w + x.x + 1] = y
    end
end

-- An iterator for each cell of the grid.
function Grid:rows()
    local i   =  0
    local row = -1
    local col = -1
    return function()
        row = row + 1

        if row >= self.h then
            return nil
        else
            return row, function()
                col = col + 1

                if col >= self.w then
                    col = -1
                    return nil
                else
                    i = i + 1
                    return col, self.cells[i]
                end
            end
        end
    end
end

function Grid:fov(pos,radius)
    for _,cell in ipairs(self.cells) do
        if cell.light > 0 then
            cell.light = 0.5
        end
    end

    local dx, dy = 0, 0
    for rad=0,2 * math.pi,0.1 do
        dx = math.sin(rad)
        dy = math.cos(rad)
        for cell in self:castRay(pos,dx,dy,radius) do
            cell.light = 1.0
            if cell:blocksLight() then
                break
            end
        end
    end
end

function Grid:castRay(pos,dx,dy,len)
    local x, y = pos.x, pos.y
    local i = 0

    x = x - dx
    y = y - dy

    return function()
        if i < len then
            i = i + 1
            x = x + dx
            y = y + dy
            return self:get(math.floor(x), math.floor(y))
        else
            return nil
        end
    end
end

function Grid:blit(opts)
    if opts.dest == nil then
        return
    end

    opts.x = opts.x or self.x
    opts.y = opts.y or self.y
    opts.w = opts.w or self.w
    opts.h = opts.h or self.h

    for j=0,opts.h-1 do
        for i=0,opts.w-1 do
            opts.dest:set(opts.x+i,opts.y+j, self:get(i,j))
        end
    end
end

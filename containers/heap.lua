
local Heap = {}
Heap.__index = Heap

function Heap.create(cmp)
    return setmetatable({
        cmp = cmp or function(x,y) return x < y end,
        max = 1,
    }, Heap)
end

-- Generate child indices for 1-based arrays.
local function children(i)
    local ix = 2 * (i-1) + 2
    return ix, ix + 1
end

-- Generate the parent index for 1-based arrays.
local function parent(i)
    return math.floor((i-2) / 2) + 1
end

function Heap:insert(x)
    local ix = self.max
    local p, a, b

    self[ix] = x

    while ix > 1 do
        p = parent(ix)

        a = self[p]
        b = self[ix]

        if self.cmp(a, b) then
            break
        else
            self[p]  = b
            self[ix] = a
            ix = p
        end
    end

    self.max = self.max + 1
    return self
end

local function swap(arr, a, b)
    arr[a], arr[b] = arr[b], arr[a]
end

function Heap:remove()
    if self.max > 1 then
        local res = self[1]
        self.max = self.max - 1

        self[1]        = self[self.max]
        self[self.max] = nil

        local ix = 1
        local largest, left, right, node

        while true do
            left, right = children(ix)
            largest     = ix
            node        = self[ix]

            if left < self.max and self.cmp(self[left], node) then
                largest = left
            end

            if right < self.max and self.cmp(self[right], node) then
                largest = right
            end

            if largest ~= ix then
                swap(self, ix, largest)
                ix = largest
            else
                break
            end
        end

        return res
    else
        return nil
    end
end

function Heap:isEmpty()
    return self.max <= 1
end

function Heap:__len()
    return self.max - 1
end

return Heap

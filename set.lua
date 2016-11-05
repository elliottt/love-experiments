
Set = {}

function Set:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Set.create(hash)
    return Set:new{
        elems = {},
        hash  = hash or function(x) return x end,
    }
end

function Set:member(x)
    local bucket = self.elems[self.hash(x)]
    if bucket then
        for _,e in ipairs(bucket) do
            if x == e then
                return true
            end
        end
    end

    return false
end

function Set:insert(x)
    local hash   = self.hash(x)
    local bucket = self.elems[hash]
    if bucket then
        for _,e in ipairs(bucket) do
            if e == x then
                return
            end
        end
    else
        bucket = {}
        self.elems[hash] = bucket
    end

    table.insert(bucket, x)

    return self
end

function Set:iter()
    local i, j, bucket, e

    local outer = true
    local iter

    function iter()
        if outer then
            i, bucket = next(self.elems, i)
            outer     = false
            j         = nil
            if bucket == nil then
                return nil
            end
        end

        j, e = next(bucket, j)
        if e then
            return e
        else
            outer = true
            return iter()
        end
    end

    return iter

end

return Set

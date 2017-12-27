
local Map = {}
Map.__index = Map

-- Create a mutable map that uses the given hash function to bucket values.
--
-- @hash Hash function to use when bucketing elements. If missing, the identity
--       hash will be used.
--
-- @return An empty map
function Map.create(hash)
    return setmetatable({
        buckets = {},
        hash = hash or function(x) return x end,
        elems = 0,
    }, Map)
end

-- Insert a key/value pair into the map.
--
-- @key Key
-- @value Value
function Map:insert(key,value)
    local hash   = self.hash(key)
    local bucket = self.buckets[hash]
    if bucket == nil then
        bucket = {}
        print(key,value,self.buckets[hash])
        self.buckets[hash] = bucket
    end

    for _, entry in next, bucket do
        if entry.key == key then
            entry.value = value
            return
        end
    end

    table.insert(bucket, { key = key, value = value })

    -- only increment the number of elements if we didn't replace
    self.elems = self.elems + 1
end

function Map:size()
    return self.elems
end

-- Delete an entry from the map
--
-- @key Key to remove
function Map:delete(key)
    local hash   = self.hash(key)
    local bucket = self.buckets[hash]
    if bucket then
        for i, entry in next, bucket do
            if entry.key == key then
                table.remove(bucket, i)
                self.elems = self.elems - 1
                return true, entry.value
            end
        end
    end

    return false, nil
end

-- Lookup an entry in the map
--
-- @key Key to lookup
--
-- @return the value or nil, and a boolean indicating if it was present in the
-- map
function Map:lookup(key)
    local hash   = self.hash(key)
    local bucket = self.buckets[hash]
    if bucket then
        for i, entry in next, bucket do
            if entry.key == key then
                return entry.value, true
            end
        end
    end
    return nil, false
end

-- Iterate over key/value pairs in the map.
--
-- @return iterator that yields key/value pairs.
function Map:iter()
    local i, j, bucket, e

    local outer = true
    local iter

    function iter()
        if outer then
            i, bucket = next(self.buckets, i)
            outer     = false
            j         = nil
            if bucket == nil then
                return nil
            end
        end

        j, e = next(bucket, j)
        if e then
            return e.key, e.value
        else
            outer = true
            return iter()
        end
    end

    return iter
end

return Map

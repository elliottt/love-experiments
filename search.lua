
local Set  = require 'containers.set'
local Heap = require 'containers.heap'

local search = {}


-- Search for a state that satisfies the equation measure(state) == 0. Each
-- iteration of the search extends the current node with the extension function,
-- then adds them to the work queue (assuming they haven't been seen yet).
--
-- @state   : a
-- @hash    : a -> num
-- @extend  : a -> [a]
-- @measure : a -> num
-- @bound   : Int option
--
-- @return an array of moves, or nil if no solution was found
function search.astar(start, hash, extend, measure, bound)

    local finished
    if bound == nil then
        finished = function()
            return false
        end
    else
        local i = 0
        finished = function()
            i = i + 1
            return i > bound
        end
    end


    -- invariant: things that are in the work queue are also in the visited set.
    local visited = Set.create(hash)

    local function mkNode(parent,state)
        visited:insert(state)

        local cost
        if parent then
            cost = parent.cost + 1
        else
            cost = 0
        end

        local distance = measure(state)
        return {
            state    = state,
            parent   = parent,
            cost     = cost,
            distance = distance,
            h        = cost + distance,
        }
    end

    local function cmp(a,b)
        return a.h <= b.h and a.distance < b.distance
    end

    local function extractPath(node)
        result = {}
        while node ~= nil do
            table.insert(result, 1, node.state)
            node = node.parent
        end

        return result
    end

    local queue = Heap.create(cmp):insert(mkNode(nil, start))

    local node
    local children
    local added
    while #queue > 0 do
        if finished() then
            break
        end

        node = queue:remove()

        if node.distance == 0 then
            return extractPath(node)
        else
            added = false
            for child, dist in extend(node.state) do
                if not visited:member(child) then
                    queue:insert(mkNode(node, child))
                end
            end
        end
    end

    return nil

end


-- Breadth-first search.
--
-- @start  : state
-- @hash   : state -> int
-- @extend : state -> [state]
-- @goal   : state -> bool
function search.bfs(start, hash, extend, goal)

    local visited = Set.create(hash):insert(start)

    local function mkNode(parent, state)
        visited:insert(state)

        return {
            parent = parent,
            state = state,
        }
    end

    local function extractPath(node)
        path = {}
        while node ~= nil do
            table.insert(path, 1, node.state)
            node = node.parent
        end

        return path
    end

    local node
    local queue = { mkNode(nil, start) }

    while #queue > 0 do

        node = table.remove(queue, 1)

        if goal(node.state) then
            return extractPath(node)
        else
            for _, child in ipairs(extend(node.state)) do
                if not visited:member(child) then
                    table.insert(queue, mkNode(node, child))
                end
            end
        end

    end

    return nil

end

return search

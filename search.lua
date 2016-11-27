
Set = require 'containers.set'


local search = {}


-- Search for a state that satisfies the equation measure(state) == 0. Each
-- iteration of the search extends the current node with the extension function,
-- then adds them to the work queue (assuming they haven't been seen yet).
--
-- @state   : a
-- @hash    : a -> Int
-- @extend  : a -> [a]
-- @measure : a -> Int
-- @bound   : Int
--
-- @return an array of moves, or nil if no solution was found
function search.astar(start, hash, extend, measure, bound)

    bound = bound or 100

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

    local function comp(a,b)
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

    local queue = { mkNode(nil, start) }

    local node
    local children
    local it = 0
    local added
    while #queue > 0 do
        it = it + 1
        if it > bound then
            break
        end

        node = table.remove(queue,1)

        if node.distance == 0 then
            return extractPath(node)
        else
            added = false
            for _,child in ipairs(extend(node.state)) do
                if not visited:member(child) then
                    table.insert(queue, mkNode(node, child))
                    added = true
                end
            end

            if added then
                table.sort(queue, comp)
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

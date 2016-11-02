

local search = {}


-- Search for a state that satisfies the equation measure(state) == 0. Each
-- iteration of the search extends the current node with the extension function,
-- then adds them to the work queue (assuming they haven't been seen yet).
--
-- @state   : a
-- @extend  : a -> [a]
-- @measure : a -> Int
--
-- @return an array of moves, or nil if no solution was found
function search.astar(start, extend, measure, bound)

    bound = bound or 100

    local function mkNode(parent,state)
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
        repeat
            table.insert(result, 1, node.state)
            node = node.parent
        until
            node.parent == nil

        return result
    end

    local visited = {}
    local queue   = { mkNode(nil, start) }

    local node
    local children
    while #queue > 0 do
        node = table.remove(queue,1)
        visited[node.state] = node

        if node.distance == 0 then
            return extractPath(node)
        else
            local added = false
            for _,child in ipairs(extend(node.state)) do
                if visited[child] == nil then
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

return search

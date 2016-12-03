
local Map = require('containers.map')

local Graph = {}
Graph.__index = Graph

-- Construct a graph that uses the given hash function for node hashing.
--
-- @hash Hash function for node hashing
--
-- @return an empty Graph
function Graph.directed(hash)
    return setmetatable({
        nodeIds    = Map.create(hash),
        nodes      = {},
        undirected = false,
    }, Graph)
end

function Graph.undirected(hash)
    return setmetatable({
        nodeIds    = Map.create(hash),
        nodes      = {},
        undirected = true,
    }, Graph)
end

-- Create a new node in the graph
--
-- @value The value of the node
function Graph:newNode(value)
    self:getNode(value)
    return self
end

-- Return the internal ID for the node value given.
function Graph:getNode(value)
    local id, exists = self.nodeIds:lookup(value)
    if exists then
        return id
    else
        table.insert(self.nodes, {
            value=value,
            edges={},
        })

        id = #self.nodes
        self.nodeIds:insert(value, id)

        return id
    end
end

-- Remove a node from the graph.
function Graph:removeNode(value)
    local removed, id = self.nodeIds:delete(value)
    if removed then
        local node = self.nodes[id]
        self.nodes[id] = nil

        -- remove any back-edges
        if self.undirected then
            for _, edge in pairs(node.edges) do
                edge.node.edges[id] = nil
            end
        else
            for _, es in self:iter() do
                es[id] = nil
            end
        end
    end
end

-- The nodes in the outgoing edges of this node.
function Graph:outgoing(a)
    local id, exists = self.nodeIds:lookup(a)
    if exists then
        local edges = self.nodes[id].edges
        local ix    = nil
        return function()
            ix, edge = next(edges, ix)
            if ix == nil then
                return nil
            end

            return edge.node.value, edge.weight
        end
    else
        return function()
            return nil
        end
    end
end

-- Create an edge between two nodes, by node id.
--
-- @a Id of the first node
-- @b Id of the second node
-- @undirected true when the edge is undirected
function Graph:newEdge(a,b,weight)
    local aId   = self:getNode(a)
    local bId   = self:getNode(b)
    local aNode = self.nodes[aId]
    local bNode = self.nodes[bId]
    aNode.edges[bId] = {
        node=bNode,
        weight=weight,
    }

    if self.undirected then
        bNode.edges[aId] = {
            node=aNode,
            weight=weight,
        }
    end

    return self
end

-- Node traversal.
function Graph:iter()
    local len = #self.nodes
    local i = 1
    return function()
        local entry
        repeat
            entry = self.nodes[i]
            i=i+1
        until (entry ~= nil or i > len)

        if entry then
            return entry.value, entry.edges
        else
            return nil
        end
    end
end

-- Breadth-first iteration from a given starting point.
--
-- @start The node to start the traversal from
function Graph:bfs(start)
    local startId
    if start == nil then
        startId = 1
    else
        startId = self.nodeIds[start]
    end

    local visited = { [startId] = true }
    local work    = { self.nodes[startId] }

    return function()
        local node = table.remove(work, 1)
        if node == nil then
            return nil
        end

        for id, other in pairs(node.edges) do
            if visited[id] ~= true then
                visited[id] = true
                table.insert(work, other.node)
            end
        end

        return node.value, node, id
    end
end

-- Produces an array of graphs which represent the connected sub-graphs.
function Graph:components()
    local components = {}

    local nodes = {}
    for i, node in pairs(self.nodes) do
        nodes[i] = { node=node, visited=false }
    end

    local component, work, node, other
    for _, entry in pairs(nodes) do
        if not entry.visited then
            component = Graph.create():newNode(entry.node.value)
            work = { entry }
            entry.visited = true

            while #work > 0 do
                node = table.remove(work, 1)
                node.visited = true

                for i in pairs(node.node.edges) do
                    other = nodes[i]

                    if not other.node.visited then
                        component:newNode(other.node.value)
                        other.visited = true
                        table.insert(work, other)
                    end

                    component:newEdge(node.node.value, other.node.value)
                end
            end

            table.insert(components, component)
        end
    end

    return components
end

return Graph

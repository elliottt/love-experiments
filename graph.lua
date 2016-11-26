
Graph = {}

function Graph:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Graph.create()
    return Graph:new{
        nodeIds = {},
        nodes   = {},
        edges   = {},
    }
end

-- Create a new node in the graph
--
-- @value The value of the node
function Graph:newNode(value)
    self:getNode(value)
    return self
end

function Graph:getNode(value)
    local id = self.nodeIds[value]
    if id == nil then
        table.insert(self.nodes, {
            value=value,
            edges={},
        })

        id = #self.nodes
        self.nodeIds[value] = id
    end

    return id
end

-- Create an edge between two nodes, by node id.
--
-- @a Id of the first node
-- @b Id of the second node
-- @undirected true when the edge is undirected
function Graph:newEdge(a,b,undirected)
    local aId   = self:getNode(a)
    local bId   = self:getNode(b)
    local aNode = self.nodes[aId]
    local bNode = self.nodes[bId]
    aNode.edges[bId] = bNode
    if undirected then
        bNode.edges[aId] = aNode
    end

    return self
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
                table.insert(work, other)
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

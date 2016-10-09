
Queue = {}
Queue.__index = Queue

function Queue.new()
    local self = setmetatable({}, Queue)

    self.head = nil
    self.last = nil

    return self
end

function Queue.dequeue(self)
    if self.head then
        local value = self.head.value
        self.head = self.head.next
        return value
    else
        return nil
    end
end

function Queue.enqueue(self, a)
    local node = {
        next = nil,
        value = a
    }

    if self.head then
        self.last.next = node
    else
        self.head = node
    end

    self.last = node
end

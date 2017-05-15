

local Scheduler = {}
Scheduler.__index = Scheduler


function Scheduler.create(options)
    local o = {
        head = nil,
        tail = nil,
        getTime = options.getTime or love.timer.getTime
    }

    setmetatable(o, Scheduler)

    return o
end



function Scheduler:add(thread)

    local node = {
        thread = thread,
        child = nil,
        lastUpdate = self.getTime(),
        deadline = 0,
        killed = false,
    }

    if self.head == nil then
        self.head  = node
        self.tail  = node
    else
        self.tail.child = node
        self.tail       = node
    end

    node.child = head
end

function Scheduler:remove(prev, node)

    -- is this a singleton list?
    if node == prev then
        self.head = nil
        self.tail = nil
    else
        -- is the node being removed the head?
        if node == self.head then
            self.head = node.child

        -- or the tail?
        elseif node == self.tail then
            self.tail = prev
        end

        -- fix the link
        prev.child = node.child

    end

end

function Scheduler:run()

    local now = self.getTime()

    -- nothing to run?
    if self.head == nil then
        return
    end

    local cursor = self.head
    local prev   = self.tail
    local diff   = 0
    local ok, sleep, amount = true, false, 0

    local len = 0

    -- run each thread for one iteration
    repeat

        if cursor.killed then
            ok = false
        elseif cursor.deadline < now then
            diff = now - cursor.lastUpdate
            ok, sleep, amount = coroutine.resume(cursor.thread, diff, cursor.thread)
        end

        -- update time
        now = self.getTime()

        -- if the thread had an error, remove it from the queue
        if ok == false or coroutine.status(cursor.thread) == 'dead' then
            cursor = self:remove(prev, cursor)
            if sleep ~= nil then
                print(sleep)
            end

        else
            -- if sleeping, set the deadline to now + amount
            if sleep then
                cursor.deadline = now + amount
            end

            prev              = cursor
            cursor.lastUpdate = now
            cursor            = cursor.child
        end

        len = len + 1

    until (cursor == nil or cursor == self.head)

    print('tick', now, len)

end


function Scheduler:kill(thread)

    local cursor = self.head

    if cursor == nil then
        return
    end

    repeat

        if cursor.thread == thread then
            cursor.killed = true
            break
        end

        cursor = cursor.child

    until (cursor == nil or cursor == self.head)

end


local Thread = {}
Thread.__index = Thread

local scheduler = nil

function Thread.init(options)
    scheduler = Scheduler.create(options or {})
end

function Thread.fork(fn)
    local thread = coroutine.create(fn)
    scheduler:add(thread)

    return thread
end


-- Return to the scheduler.
function Thread.yield()
    return coroutine.yield()
end


-- Kill the thread with this id.
function Thread.kill(thread)
    return scheduler:kill(thread)
end


-- Sleep for the given amount of time
function Thread.sleep(amount)
    coroutine.yield(true, amount)
end


-- Step the scheduler.
function Thread.update()
    scheduler:run()
end

return Thread

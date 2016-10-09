
local running = {
    threads = {},
}

-- Fork off a local thread, returning its id.
function fork(fun)
    local entry = {
        thread     = nil,
        lastUpdate = love.timer.getTime(),
        running    = true,
    }

    table.insert(running.threads, entry)

    local id = #running.threads
    entry.thread = coroutine.create(fun, id)

    return id
end

-- Return to the scheduler.
function yield()
    return coroutine.yield()
end

-- Kill the thread with this id.
function kill(ref)
    local thread = running.threads[ref]
    if thread ~= nil then
        running.threads[ref] = nil
    end
end

-- Sleep for this much time.
--
-- Currently, this sleeps by updating an accumulator on the running queue, but
-- it would be nice to have a sleeping queue that was sorted on wakeup time
-- instead.
function sleep(amount)
    local elapsed = 0
    local diff    = 0
    while true do
        diff    = yield()
        elapsed = elapsed + diff
        if elapsed >= amount then
            return elapsed
        end
    end
end

-- Cause the thread to be skipped in the scheduler.
function pause(ref)
    local thread = running.threads[ref]
    if thread then
        thread.running = false
    end
end

-- Resume a paused thread.
function resume(ref)
    local thread = running.threads[ref]
    if thread then
        thread.running = true
    end
end

-- Step the scheduler.
function step(options)
    local getTime = options.getTime or love.timer.getTime
    local now     = 0.0

    local threads = running.threads
    local start   = nil
    local diff    = nil

    for key, co in ipairs(threads) do
        if co.running then
            start = getTime()
            diff  = start - co.lastUpdate
            coroutine.resume(co.thread, diff)
            if coroutine.status(co.thread) == 'dead' then
                threads[key] = nil
            else
                co.lastUpdate = getTime()
            end
        end
    end
end

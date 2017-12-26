
local Thread = require 'threads'


local Handle = {}
Handle.__index = Handle

function Handle.new(method, duration)
    return setmetatable({
            method = method,
            step_cb = nil,
            finish_cb = nil,
            running = true,
            duration = duration,
        }, Handle)
end

function Handle:start()
    self.thread = Thread.fork(function(dt)

        local now = 0

        local state = nil
        while self.running do
            state = self.method(self, now / self.duration, now)
            if self.step_cb then
                self.step_cb(state, handle)
            end

            dt = Thread.yield()
            now = now + dt

            if now >= self.duration then
                break
            end
        end

        if self.finish_cb then
            self.finish_cb(state, handle)
        end
    end)

    return self
end

function Handle:cancel()
    self.running = false

    return self
end

function Handle:onStep(callback)
    self.step_cb = callback

    return self
end

function Handle:onFinish(callback)
    self.finish_cb = callback

    return self
end


Tween = {}
Tween.__index = Tween

function Tween.linear(s,e,duration)
    local diff = e - s
    return Handle.new(function(handle, scale, dt)
        return s + diff * scale;
    end, duration)
end

return Tween

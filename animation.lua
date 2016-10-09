
require 'threads'
require 'sprites'

Frame = {}
Frame.__index = Frame

function Frame.new(sprite, delay)
    local self = setmetatable({}, Frame)
    self.sprite = sprite
    self.delay  = delay
    return self
end

function Frame.draw(self,x,y)
    self.sprite:draw(x,y)
end


local animations = {}

function initAnimation()
    fork(function()
        local diff = 0
        while true do
            diff = yield()
            for key,anim in ipairs(animations) do
                anim.acc = anim.acc + diff
                while anim.acc >= anim.current.delay do
                    anim.acc     = anim.acc - anim.current.delay
                    anim.ix      = (anim.ix % anim.len) + 1
                    anim.current = anim.frames[anim.ix]
                end
            end
        end
    end)
end


Animation = {}
Animation.__index = Animation

function Animation.new(frames)
    local self = setmetatable({}, Animation)

    self.frames  = frames
    self.len     = #frames
    self.ix      = 1
    self.current = frames[self.ix]
    self.acc     = 0

    table.insert(animations, self)

    return self
end

function Animation.start(self)
    continue(self.name)
end

function Animation.draw(self, x, y)
    self.current:draw(x,y)
end


-- lovebird = require 'lovebird'

require 'threads'
require 'animation'
require 'model'
require 'view'

local model = nil
local view  = nil

function love.load()
    initAnimation()

    model = Model.new()
    view  = View.new()

    view:load()
end

function love.draw()
    love.graphics.push()
    love.graphics.scale(4,4)
    view:draw(model)
    love.graphics.pop()
end

local keys = {
    q = function()
        love.event.quit()
    end,

    h = function()
        model:move(Pos.moveWest)
    end,

    j = function()
        model:move(Pos.moveSouth)
    end,

    k = function()
        model:move(Pos.moveNorth)
    end,

    l = function()
        model:move(Pos.moveEast)
    end,
}

function love.keypressed(k)
    handler = keys[k]
    if handler then
        handler()
    end
end

function love.update()
    step{}
end

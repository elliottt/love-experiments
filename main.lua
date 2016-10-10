
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

-- Key handlers
local keys = {
    q = function()
        love.event.quit()
    end,

    h = function()
        model:movePlayer(Pos.moveWest)
    end,

    j = function()
        model:movePlayer(Pos.moveSouth)
    end,

    k = function()
        model:movePlayer(Pos.moveNorth)
    end,

    l = function()
        model:movePlayer(Pos.moveEast)
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

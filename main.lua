
-- lovebird = require 'lovebird'

local Thread = require 'threads'

require 'animation'
require 'game.model'
require 'view'
require 'game-state'

local menu  = MenuState:new()
local game  = PlayingState:new()
local state

menu:init(game)
game:init(menu)

local function switchTo(newState)
    state = newState
    state:enter()
end

function love.load()
    Thread.init()

    initAnimation()

    love.keyboard.setKeyRepeat(true)

    menu:load()
    game:load()

    switchTo(game)
end

function love.mousepressed(x,y,b,t)
    state:mousepressed(x,y,b,t)
end

function love.mousereleased(x,y,b,t)
    state:mousereleased(x,y,b,t)
end

function love.mousemoved(x,y,dx,dy,t)
    state:mousemoved(x,y,dx,dy,t)
end

function love.wheelmoved(x,y)
    state:wheelmoved(x,y)
end

function love.draw()
    love.graphics.push()
    state:draw()
    love.graphics.pop()
end

function love.keypressed(key,scan,isrepeat)
    local newState = state:keypressed(key,scan,isrepeat)
    if newState ~= nil then
        switchTo(newState)
    end
end

function love.update()
    Thread.update()
    state:update()
end

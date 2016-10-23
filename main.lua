
-- lovebird = require 'lovebird'

require 'threads'
require 'animation'
require 'game.model'
require 'view'
require 'game-state'
require 'event'

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

function love.draw()
    love.graphics.push()
    state:draw()
    love.graphics.pop()
end

function love.keypressed(key,scan,isrepeat)
    local newState = state:keypressed(key,scan,isrepeat)
    if newState then
        switchTo(newState)
    end
end

function love.update()
    step{}
    state:update()
end

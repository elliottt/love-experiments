
require 'game.model'
require 'view'


GameState = {
    keys = {}
}

function GameState:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function GameState:enter()
end

function GameState:init()
end

function GameState:load()
end

function GameState:update(dt)
end

function GameState:draw()
end

function GameState:mousepressed()
end

function GameState:mousereleased()
end

function GameState:mousemoved()
end

function GameState:keypressed(key,scan,isrepeat)
    local handler = self.keys[key]
    if handler then
        return handler(self,scan,isrepeat)
    else
        return nil
    end
end

function GameState:keyreleased(key,scan)
end



MenuState = GameState:new{
    game = nil,
    keys = {
        n = function(self)
            return self.game
        end,

        q = function(self)
            love.event.quit()
        end,
    }
}

function MenuState:init(game)
    self.game = game
    self.dragging = false
end

function MenuState:draw()
    love.graphics.print('Press `n` to start a new game', 100, 100)
end


PlayingState = GameState:new{
    menu  = nil,
    model = nil,
    view  = nil,
    keys  = {
        q = function(self)
            return self.menu
        end,

        h = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(Pos.moveWest)
            end)
        end,

        j = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(Pos.moveSouth)
            end)
        end,

        k = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(Pos.moveNorth)
            end)
        end,

        l = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(Pos.moveEast)
            end)
        end,

        ['.'] = function(self)
            self.model:takeStep(function()
            end)
        end,

        space = function(self)
            self.model:takeStep(function()
                self.model:interact()
            end)
        end,
    }
}

function PlayingState:enter()
    self.model = Model.create{
        mapWidth = 32,
        mapHeight = 32,
    }
end

function PlayingState:mousepressed(x,y,button)
    if button == 1 then
        self.dragging = true
    end
end

function PlayingState:mousereleased()
    self.dragging = false
end

function PlayingState:mousemoved(x,y,dx,dy)
    if self.dragging then
        self.view:moveBy(dx,dy)
    end
end

function PlayingState:init(menu)
    self.menu = menu
    self.view = View.create()
end

function PlayingState:load()
    self.view:load()
end

function PlayingState:draw()
    self.view:draw(self.model)
end

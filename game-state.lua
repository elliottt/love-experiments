
require 'game.model'
require 'view'
require 'sprites'


GameState = {
    kind = {},
    keys = nil,
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

function GameState:wheelmoved()
end

function GameState:keypressed(key,scan,isrepeat)
    if self.keys == nil then
        return
    end

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
    kind = {},
    game = nil,
    keys = {
        n = function(self)
            return self.game
        end,

        q = function(self)
            love.event.quit()
        end,

        a = function(self)
            return SpriteSheetView:new():init(self, 'sprites/roguelikeChar_transparent.png')
        end,

        b = function(self)
            return SpriteSheetView:new():init(self, 'sprites/roguelikeDungeon_transparent.png')
        end,

        c = function(self)
            return SpriteSheetView:new():init(self, 'sprites/roguelikeSheet_transparent.png')
        end,

        d = function(self)
            return TweenDemo:new():init(self)
        end,
    }
}

function MenuState:init(game)
    self.game = game
    self.dragging = false
end

function MenuState:draw()
    love.graphics.print('Press `n` to start a new game', 100, 100)
    love.graphics.print('Press `a` to view character sheet', 100, 120)
    love.graphics.print('Press `b` to view dungeon sheet', 100, 130)
    love.graphics.print('Press `c` to view roguelike sheet', 100, 140)
end


PlayingState = GameState:new{
    kind  = {},
    menu  = nil,
    model = nil,
    view  = nil,
    keys  = {
        q = function(self)
            return self.menu
        end,

        v = function(self)
            self.view:toggleTint()
            self.model:toggleDebug()
        end,

        h = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(West)
            end)
        end,

        u = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(NorthEast)
            end)
        end,

        y = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(NorthWest)
            end)
        end,

        b = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(SouthWest)
            end)
        end,

        n = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(SouthEast)
            end)
        end,

        j = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(South)
            end)
        end,

        k = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(North)
            end)
        end,

        l = function(self)
            self.model:takeStep(function()
                self.model:movePlayer(East)
            end)
        end,

        x = function(self)
            self.model:takeStep(function()
                self.model:searchStep()
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
    self.view:reset()
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


SpriteSheetView = GameState:new{
    kind = {},
    menu = nil,
    dragging = false,
    x = 0,
    y = 0,
    scale = 1,
    keys = {
        q = function(self)
            return self.menu
        end,
    }
}

function SpriteSheetView:init(menu, file)
    self.menu = menu

    self.sheet =
        SpriteSheet.create(file, {
            width = 16,
            height = 16,
            border_x = 1,
            border_y = 1,
        })

    return self
end

function SpriteSheetView:mousepressed(x,y,button)
    if button == 1 then
        self.dragging = true
    end
end

function SpriteSheetView:mousereleased()
    self.dragging = false
end

function SpriteSheetView:mousemoved(x,y,dx,dy)
    if self.dragging then
        self.x = self.x + dx
        self.y = self.y + dy
    end
end

function SpriteSheetView:wheelmoved(x,y)
    if y > 0 then
        self.scale = math.max(1, self.scale - 0.1)
    elseif y < 0 then
        self.scale = math.min(self.scale + 0.1, 4)
    end
end

function SpriteSheetView:draw()
    local mx = (love.mouse.getX() - self.x) / self.scale
    local my = (love.mouse.getY() - self.y) / self.scale
    local inBounds = mx >= 0 and mx < self.sheet.image:getWidth()
                 and my >= 0 and my < self.sheet.image:getHeight()

    love.graphics.push('transform')
    love.graphics.translate(self.x, self.y)
    love.graphics.scale(self.scale, self.scale)

    self.sheet:draw(0,0)

    if inBounds then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(255, 255, 255, 100)
        local x, y = self.sheet:cellAlign(mx,my)
        love.graphics.rectangle('fill', x, y, self.sheet.width, self.sheet.height)
        love.graphics.setColor(r,g,b,a)
    end

    love.graphics.pop()

    if inBounds then

        love.graphics.print(string.format('%d x %d', self.sheet:cellIx(mx,my)), 0, 0)


    end
end


local Tween = require 'tween'

TweenDemo = GameState:new{
    kind = {},
    tween = nil,

    x = 0,

    keys = {
        q = function(self)
            return self.menu
        end,

        space = function(self)
            self.tween:cancel()
            return self
        end,
    },
}


function TweenDemo:init(menu)
    local time

    self.tween = Tween.linear(0,10,1.0)

    self.menu = menu
    self.msg = 'starting...'

    self.tween:onStep(function(x)
        self.msg = 'stepping: ' .. tostring(x)
    end):onFinish(function(x)
        time = love.timer.getTime() - time
        self.msg = 'done! (' .. x .. ", " .. time .. 's)'
    end):start()

    time = love.timer.getTime()

    return self
end

function TweenDemo:draw()
    love.graphics.print(self.msg, 100, 100)
end

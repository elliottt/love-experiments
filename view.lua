
require 'sprites'

View = {}

function View:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function View.create()
    return View:new{
        charSheet = nil,
        playerSprite = nil,
        cellWidth = 16,
        cellHeight = 16,
    }
end

function View:load()

    self.charSheet =
        SpriteSheet.create('sprites/roguelikeChar_transparent.png', {
            width = self.cellWidth,
            height = self.cellHeight,
            border_x = 1,
            border_y = 1,
        })

    self.dungeonSheet =
        SpriteSheet.create('sprites/roguelikeDungeon_transparent.png', {
            width = self.cellWidth,
            height = self.cellHeight,
            border_x = 1,
            border_y = 1,
        })

    self.playerSprite = Animation.new{
        Frame.new(self.charSheet:get(0,0), 0.1),
        Frame.new(self.charSheet:get(1,0), 0.5),
    }

end


function View:draw(model)

    love.graphics.scale(4,4)

    self.playerSprite:draw(model.player.pos.x * self.cellWidth,
            model.player.pos.y * self.cellHeight)

    for row,elems in model:map():rows() do
        for col,cell in elems do
            love.graphics.push()
            love.graphics.translate(self.cellWidth * col, self.cellHeight * row)
            self:drawCell(cell)
            love.graphics.pop()
        end
    end
end

function View:drawCell(cell)

    love.graphics.print('x', 0, 0)

end

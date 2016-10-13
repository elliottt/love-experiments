
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
            off_x = 1,
            off_y = 1,
            width = self.cellWidth,
            height = self.cellHeight,
            border_x = 1,
            border_y = 1,
        })

    self.tiles = {}
    self.tiles[Floor.kind] = self.dungeonSheet:get(16,14)
    self.tiles[Wall.kind]  = self.dungeonSheet:get(16,10)
    self.tiles[Door.kind]  = self.dungeonSheet:get(24,1)

    self.playerSprite = Animation.new{
        Frame.new(self.charSheet:get(0,0), 0.1),
        Frame.new(self.charSheet:get(1,0), 0.5),
    }

end


function View:draw(model)

    love.graphics.scale(4,4)

    for row,elems in model:map():rows() do
        for col,cell in elems do
            love.graphics.push()
            love.graphics.translate(self.cellWidth * col, self.cellHeight * row)
            self:drawCell(cell)
            love.graphics.pop()
        end
    end

    self.playerSprite:draw(model.player.pos.x * self.cellWidth,
            model.player.pos.y * self.cellHeight)

end

function View:drawCell(cell)
    if cell then
        self.tiles[cell.kind]:draw(0,0)
    end
end

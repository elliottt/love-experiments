
require 'sprites'

View = {}
View.__index = View

function View.new(model)
    local self = setmetatable({}, View)

    self.cellWidth  = 16
    self.cellHeight = 16

    return self
end


function View.load(self)

    self.charSheet = SpriteSheet.new('sprites/roguelikeChar_transparent.png',
            0, 0, 16, 16, 1, 1)

    self.playerSprite = Animation.new{
        Frame.new(self.charSheet:get(0,0), 0.1),
        Frame.new(self.charSheet:get(1,0), 0.5),
    }

end


function View.draw(self, model)

    self.playerSprite:draw(model.player.pos.x * self.cellWidth,
            model.player.pos.y * self.cellHeight)

end

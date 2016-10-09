
Sprite = {}
Sprite.__index = Sprite

function Sprite.new(image, x, y, w, h)
    local self = setmetatable({}, Sprite)
    self.quad  = love.graphics.newQuad(x, y, w, h, image:getDimensions())
    self.image = image
    return self
end

function Sprite.draw(self, x, y)
    love.graphics.draw(self.image, self.quad, x, y)
end

SpriteSheet = {}
SpriteSheet.__index = SpriteSheet

function SpriteSheet.new(path, off_x, off_y, width, height, border_x, border_y)
    local self    = setmetatable({}, SpriteSheet)

    self.image    = love.graphics.newImage(path)
    self.image:setFilter('nearest', 'nearest')

    self.loaded   = {}
    self.width    = width
    self.height   = height
    self.off_x    = off_x
    self.off_y    = off_y
    self.border_x = border_x
    self.border_y = border_y
    return self
end

-- Load/cache sprites from the sprite sheet.
function SpriteSheet.get(self,x,y)
    local row = self.loaded[x]
    local img = nil
    if row then
        img = row[y]
        if img then
            return img
        end
    else
        row = {}
        self.loaded[x] = row
    end

    img = Sprite.new(self.image,
            self.off_x + x * (self.width  + self.border_x),
            self.off_y + y * (self.height + self.border_y),
            self.width, self.height)
    row[y] = img

    return img
end

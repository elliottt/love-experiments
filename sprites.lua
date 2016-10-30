
Sprite = {
    quad  = nil,
    image = nil,
}

function Sprite:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Sprite.create(image, x, y, w, h)
    local sprite = Sprite:new()
    sprite.quad  = love.graphics.newQuad(x, y, w, h, image:getDimensions())
    sprite.image = image
    return sprite
end

function Sprite.draw(self, x, y)
    love.graphics.draw(self.image, self.quad, x, y)
end


SpriteSheet = {
    off_x = 0,
    off_y = 0,
    width = 0,
    height = 0,
    border_x = 0,
    border_y = 0,
    image = nil,
}

function SpriteSheet:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function SpriteSheet.create(path, opts)
    local sheet = SpriteSheet:new(opts)
    sheet.image = love.graphics.newImage(path)
    sheet.image:setFilter('nearest', 'nearest')
    sheet.loaded = {}
    sheet.cols  = math.floor((sheet.image:getWidth()  - opts.off_x)
            / (opts.width  + opts.border_x))
    sheet.rows = math.floor((sheet.image:getHeight() - opts.off_y)
            / (opts.height + opts.border_y))
    return sheet
end

-- Load/cache sprites from the sprite sheet.
function SpriteSheet:get(x,y)
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

    img = Sprite.create(self.image,
            self.off_x + x * (self.width  + self.border_x),
            self.off_y + y * (self.height + self.border_y),
            self.width, self.height)
    row[y] = img

    return img
end

function SpriteSheet:draw(x,y)
    love.graphics.draw(self.image, x, y)
end

function SpriteSheet:cellIx(x,y)
    return math.floor((y - self.off_y) / (self.height + self.border_y)),
           math.floor((x - self.off_x) / (self.width  + self.border_x))
end

function SpriteSheet:cellAlign(x,y)
    return math.floor(x - self.off_x - (x % (self.width  + self.border_x)) + self.border_x),
           math.floor(y - self.off_y - (y % (self.height + self.border_y)) + self.border_y)
end

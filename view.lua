
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
        offx = 0,
        offy = 0,
        tintVal = false,
    }
end

function View:load()

    self.tint = love.graphics.newShader('shaders/tint.glsl')

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

    self.roguelikeSheet =
        SpriteSheet.create('sprites/roguelikeSheet_transparent.png', {
            off_x = 1,
            off_y = 1,
            width = self.cellWidth,
            height = self.cellHeight,
            border_x = 1,
            border_y = 1,
        })

    self.tiles = {
        [Floor.kind] = {
            self.dungeonSheet:get(16,14),
        },

        [Hall.kind] = {
            self.dungeonSheet:get(16,14),
        },

        [Wall.kind] = {
            self.dungeonSheet:get(16,10),
        },

        [Door.kind] = {
            self.dungeonSheet:get(16,14),
            self.roguelikeSheet:get(33,1),
            self.roguelikeSheet:get(35,1),
        },

        [UpStairs.kind] = {
            self.dungeonSheet:get(16,14),
            self.roguelikeSheet:get(35,18),
        },

        [DownStairs.kind] = {
            self.dungeonSheet:get(16,14),
            self.roguelikeSheet:get(37,18),
        },

        [Chest.kind] = {
            self.roguelikeSheet:get(38,11),
            self.roguelikeSheet:get(38,10),
        },

        [Player.kind] = {
            Animation.new{
                Frame.new(self.charSheet:get(0,0), 0.1),
                Frame.new(self.charSheet:get(1,0), 0.5),
            },
        },

        [Monster.kind] = {
            Animation.new{
                Frame.new(self.charSheet:get(0,3), 0.1),
                Frame.new(self.charSheet:get(1,3), 0.5),
            },
        },

        [Corpse.kind] = {
            self.dungeonSheet:get(2,2),
        }
    }

    self.special = {
        [Chest.kind] = function(chest,tiles,x,y)
            if chest.open then
                tiles[1]:draw(x,y)
            else
                tiles[2]:draw(x,y)
            end
        end,

        [Door.kind] = function(door,tiles)
            tiles[1]:draw(0,0)
            if door.locked then
                tiles[3]:draw(0,0)
            else
                tiles[2]:draw(0,0)
            end
        end,
    }

end


function View:center(model, scale)
    local div = 2 * scale
    love.graphics.scale(scale,scale)
    love.graphics.translate(
            self.offx +
            love.graphics.getWidth()  / div
            - model.player.pos.x * self.cellWidth
            - self.cellWidth / 2,
            self.offy +
            love.graphics.getHeight() / div
            - model.player.pos.y * self.cellHeight
            - self.cellHeight / 2)
end

function View:moveBy(dx,dy)
    self.offx = self.offx + dx
    self.offy = self.offy + dy
end

function View:toggleTint()
    if self.tintVal == false then
        self.tintVal = 1.0
    else
        self.tintVal = false
    end
end

function View:draw(model)

    self:center(model, 1)

    -- draw the base tiles
    love.graphics.setShader(self.tint)
    for row,elems in model:map():rows() do
        for col,cell in elems do
            love.graphics.push('transform')
            love.graphics.translate(self.cellWidth * col, self.cellHeight * row)

            self.tint:send('tint', self.tintVal or cell.light)
            self:drawCell(cell)

            love.graphics.pop()
        end
    end
    love.graphics.setShader()

end

function View:drawCell(cell)
    self:drawTile(cell,0,0)

    if cell.prop then
        self:drawTile(cell.prop,0,0)
    end

    -- always just draw the top item, if it exists
    if cell.items[1] then
        self:drawTile(cell.items[1],0,0)
    end

    if cell.entity and (cell.light >= 0.8 or self.tintVal ~= false) then
        self:drawEntity(cell.entity)
    end
end

function View:drawTile(thing,x,y)
    local special = self.special[thing.kind]
    local tiles   = self.tiles[thing.kind]
    if special ~= nil then
        special(thing,tiles,x,y)
    elseif tiles ~= nil then
        for i,tile in ipairs(tiles) do
            tile:draw(x,y)
        end
    end
end

function View:drawEntity(entity)
    self:drawTile(entity,0,-8)
end

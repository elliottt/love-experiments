
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

        [Wall.kind] = {
            self.dungeonSheet:get(16,10),
        },

        [Door.kind] = {
            self.dungeonSheet:get(24,1),
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
    }

    self.special = {
        [Chest.kind] = function(chest,tiles)
            if chest.open then
                tiles[1]:draw(0,0)
            else
                tiles[2]:draw(0,0)
            end
        end,

        [Player.kind] = function(player,tiles)
            if player.hp <= 0 then
                love.graphics.push('transform')
                love.graphics.rotate(math.pi / 2)
                love.graphics.translate(self.cellWidth, 0)
                tiles[1]:draw(0,0)
                love.graphics.pop()
            else
                tiles[1]:draw(0,0)
            end
        end,

        [Monster.kind] = function(player,tiles)
            if player.hp <= 0 then
                love.graphics.push('transform')
                love.graphics.rotate(math.pi / 2)
                love.graphics.translate(0,-self.cellWidth)
                tiles[1]:draw(0,0)
                love.graphics.pop()
            else
                tiles[1]:draw(0,0)
            end
        end,
    }

end


function View:draw(model)

    love.graphics.scale(4,4)

    -- draw the base tiles
    for row,elems in model:map():rows() do
        for col,cell in elems do
            love.graphics.push('transform')
            love.graphics.translate(self.cellWidth * col, self.cellHeight * row)

            self:drawCell(cell)

            love.graphics.pop()
        end
    end

end

function View:drawCell(cell)
    self:drawTile(cell)

    if cell.prop then
        self:drawTile(cell.prop)
    end

    if cell.entity then
        self:drawTile(cell.entity)
    end
end

function View:drawTile(thing)
    local special = self.special[thing.kind]
    local tiles   = self.tiles[thing.kind]
    if special ~= nil then
        special(thing,tiles)
    elseif tiles ~= nil then
        tiles[1]:draw(0,0)
    else
        love.graphics.print(string.format('sk %s', thing.kind == Player.kind), 0, 0)
    end
end

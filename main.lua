
-- lovebird = require 'lovebird'

require 'threads'
require 'sprites'
require 'animation'

function love.load()
    initAnimation()

    chars = SpriteSheet.new('sprites/roguelikeChar_transparent.png', 0, 0, 16,
            16, 1, 1)
    a = chars:get(0,0)
    b = chars:get(1,0)
    anim = Animation.new({
        Frame.new(chars:get(0,0), 0.1),
        Frame.new(chars:get(1,0), 0.6),
    })

    fork(function()
        while true do
            x = x + 1
            sleep(1.0)
        end
    end)

end

x = 0

function love.draw()
    love.graphics.push()
    love.graphics.scale(4,4)
    anim:draw(10,10)
    love.graphics.pop()

    love.graphics.print(string.format('awesome %d', x), 100, 100)
end

function love.keypressed(k)
    if k == 'k' then
        stop('foo')
    end

    if k == 'q' then
        love.event.quit()
    end
end

function love.update()
    --lovebird.update()
    step{}
end

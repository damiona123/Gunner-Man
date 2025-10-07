local bullet = {}
bullet.__index = bullet

-- Create a new bullet
-- x, y = starting position
-- targetX, targetY = aim position
-- speed = pixels per second
function bullet.new(x, y, targetX, targetY, speed)
    local angle = math.atan2(targetY - y, targetX - x)
    local dx = math.cos(angle) * speed
    local dy = math.sin(angle) * speed
    local obj = {
        x = x,
        y = y,
        dx = dx,
        dy = dy,
        radius = 4
    }
    setmetatable(obj, bullet)
    return obj
end

-- Update bullets table
function bullet.update(bullets, dt)
    for i = #bullets, 1, -1 do
        local b = bullets[i]
        b.x = b.x + b.dx * dt
        b.y = b.y + b.dy * dt

        -- Remove offscreen bullets
        if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
            table.remove(bullets, i)
        end
    end
end

-- Draw bullets
function bullet.draw(bullets)
    love.graphics.setColor(1, 0, 0)
    for _, b in ipairs(bullets) do
        love.graphics.circle("fill", b.x, b.y, b.radius)
    end
    love.graphics.setColor(1, 1, 1)
end

return bullet

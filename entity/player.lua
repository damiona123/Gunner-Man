local bullets = require("entity.bullet")

local player = {}
player.x = 400
player.y = 300
player.speed = 200
player.bullets = {}
player.fireRate = 0.3 -- seconds per shot
player.fireTimer = 0
player.radius = 16

function player:new(x, y, gfx)
    local obj = setmetatable({}, {__index = self})
    obj.x = x or 400
    obj.y = y or 300
    obj.gfx = gfx
    obj.bullets = {}
    obj.fireTimer = 0
    return obj
end

function player:update(dt, enemies)
    -- follow mouse
    local mx, my = love.mouse.getPosition()
    self.x = mx
    self.y = my

    -- auto-fire at nearest enemy
    self.fireTimer = self.fireTimer - dt
    if self.fireTimer <= 0 and #enemies > 0 then
        local closest = nil
        local closestDist = math.huge
        for _, e in ipairs(enemies) do
            local dx = e.x - self.x
            local dy = e.y - self.y
            local dist = dx*dx + dy*dy
            if dist < closestDist then
                closest = e
                closestDist = dist
            end
        end
        if closest then
            table.insert(self.bullets, bullets.new(self.x, self.y, closest.x, closest.y, 300))
            self.fireTimer = self.fireRate
        end
    end

    -- update bullets
    bullets.update(self.bullets, dt)

    -- bullet collision with enemies
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        for j = #enemies, 1, -1 do
            local e = enemies[j]
            if e.gfx then
                local dx = e.x - b.x
                local dy = e.y - b.y
                if math.sqrt(dx*dx + dy*dy) < (b.radius + 16) then -- enemy radius ~16
                    table.remove(enemies, j)
                    table.remove(self.bullets, i)
                    break
                end
            end
        end
    end
end

function player:draw()
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1)
    bullets.draw(self.bullets)
end

return player

require("lib")

enemy = {}
enemy.__index = enemy

windowX, windowY = love.graphics.getPixelDimensions()

function enemy:new(x, y, targetX, targetY, dx, dy, gfx, baseLerp, lifetime)
    local obj = {
        x = x or 400,
        y = y or 400,
        targetX = targetX,
        targetY = targetY,
        dx = dx or 0,
        dy = dy or 0,
        gfx = gfx or love.graphics.newImage("gfx/enemy.png"),
        pointsValue = 100,
        lifetime = math.random(lifetime, lifetime*2)/60,
        baseLerp= math.random() * baseLerp,
        scaling= randomFloat(3,4,5),
        gfxX = gfx:getWidth()/2,
        gfxY = gfx:getHeight()/2,
        rot= 0,
        radius = 16 -- added for bullet collision
    }
    setmetatable(obj, enemy)
    return obj
end

function enemy:draw()
    self.rot = self.rot + self.baseLerp + 0.02
    love.graphics.draw(self.gfx, self.x, self.y, math.sin(self.rot), self.scaling, self.scaling, self.gfxX, self.gfxY)
end

function enemy:move(dt, targetX, targetY)
    self.lifetime = self.lifetime - 1 * dt
    if self.lifetime <= 0 then return true end
    self.x = lerp(self.x, targetX, self.baseLerp)
    self.y = lerp(self.y, targetY, self.baseLerp)
    return false
end

function enemy:handleEnemyDeath(playerX, playerY, playerRadius, enemyRadius)
    return (
        (playerX < self.x + enemyRadius) and
        (playerX + playerRadius > self.x) and
        (playerY < self.y + enemyRadius) and
        (playerY + playerRadius > self.y)
    )
end

return enemy

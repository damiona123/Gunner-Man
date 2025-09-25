require("lib")

player = {}
player.__index = player

function player:new(x, y, gfx)
	local obj = {
		x = x or 100,
		y = y or 100,
		gfx = gfx or love.graphics.newImage("gfx/player.png"),
		gfxX = gfx:getWidth()/2,
        gfxY = gfx:getHeight()/2
	}
	setmetatable(obj, player)
	return obj
end

function player:moveX(start, targetX, t)
	self.x = lerp(self.x, targetX, t)
end

function player:draw()
	love.graphics.draw(self.gfx, self.x, self.y, 0, 2, 2, self.gfxX, self.gfxY)
end
require("entity/player")
require("entity/goobers")
require("lib")
local tick = require("tick")
math.randomseed(os.time())
love.graphics.setDefaultFilter("nearest", "nearest")

-- Game variables
local music = nil
local gameState = "menu" -- "menu", "playing", "dead", "exploding"
local screenShake = nil
local t, shakeDuration, magnitude = 0, 0.7, 5
local gameTimer = 0
local maxEnemies = 5
local windowX, windowY = love.graphics.getPixelDimensions()
local playerGfx = love.graphics.newImage("gfx/player.png")
local enemyGfx = love.graphics.newImage("gfx/enemy.png")
local bg = love.graphics.newImage("gfx/bg.png")
local scaleFactor = 2
local score = 0
local scoreWobble = 0
local scoreScaleFactor = 2
local spawningenemies = false
-- Explosion & death delay
local deathDelay = 2
local deathTimer = 0
local deadEnemies = {}

-- Player and enemy table
local playerObj = nil
local enemies = {}

musicOptions = {
    easy = "sfx/easy.mp3",
    medium = "sfx/medium.mp3",
    hard = "sfx/hard.ogg"
}

diffs = {
    easy = {
        baseLerp = 0.04,
        maxEnemies = 3,
        lifetime = 210
    },
    medium = {
        baseLerp = 0.055,
        maxEnemies = 4,
        lifetime = 140
    },
    hard = {
        baseLerp = 0.075,
        maxEnemies = 5,
        lifetime = 80
    }
}
diffConfig = {
    baseLerp = 0,
    maxEnemies = 0,
    lifetime = 0
}

buttons = {
    {text = "Easy", x = 20, y = 20, width = 200, height = 150, c = {0.15,0.85,0.15}, onClick = function()
        for k, v in pairs(diffs["easy"]) do
            diffConfig[k] = v
        end
        music = love.audio.newSource(musicOptions.easy, "stream")
    end},
    {text = "Medium", x = 20, y = 190, width = 200, height = 150, c = {0.15,0.15,0.85}, onClick = function()
        for k, v in pairs(diffs["medium"]) do
            diffConfig[k] = v
        end
        music = love.audio.newSource(musicOptions.medium, "stream")
    end},
    {text = "Hard", x = 20, y = 360, width = 200, height = 150, c = {0.85,0.15,0.15}, onClick = function() 
        for k, v in pairs(diffs["hard"]) do
            diffConfig[k] = v
        end
        music = love.audio.newSource(musicOptions.hard, "stream")
    end}   
}

function love.load()
    tick.framerate = 60
    playerObj = player:new(10, 10, playerGfx, {0, 0})
    enemies = {}

    music = love.audio.newSource(musicOptions.easy, "stream")
    love.audio.setVolume(0.2)
    music:setLooping(true)
end

-- State management & music
function setGameState(state)
    gameState = state
    if state == "playing" then
        if music then
            music:stop()
            music:play()
        end
    else
        if music then music:stop() end
    end
end

function resetGame()
    gameTimer = 0
    spawningenemies = false
    score = 0
    enemies = {}
    playerObj = player:new(10, 10, playerGfx)
end

function love.update(dt)
    -- Screen shake on score milestones
    if score % 500 == 0 then
        screenShake = true
    end

    if gameState == "playing" then
        gameTimer = gameTimer + 1
        score = gameTimer

        -- Mouse follow
        local mouseX, mouseY = love.mouse.getPosition()
        playerObj.x = mouseX
        playerObj.y = mouseY

        -- Spawn enemies
        if gameTimer == 60 then spawningenemies = true end

        if spawningenemies then
            if #enemies < diffConfig.maxEnemies then
                table.insert(enemies, enemy:new(
                    math.random(1, windowX), math.random(1, windowY),
                    targetX, targetY,
                    nil, nil,
                    enemyGfx,
                    diffConfig.baseLerp,
                    diffConfig.lifetime
                ))
	        end
	    end

        -- Enemy movement and collision
        local explosionTriggered = false
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            if not e then break end  -- safety check

            if e:move(dt, playerObj.x, playerObj.y) then
                table.remove(enemies, i)
            end

            local collided, _ = e:handleEnemyDeath(
                playerObj.x, playerObj.y,
                playerGfx:getWidth() * scaleFactor,
                enemyGfx:getWidth() * scaleFactor
            )

            if collided and not explosionTriggered then
                -- Trigger explosion
                deadEnemies = {}
                for j = 1, #enemies do
                    local de = enemies[j]
                    if de then
                        table.insert(deadEnemies, {
                            x = de.x,
                            y = de.y,
                            gfx = de.gfx,
                            rot = 0,
                            scaling = de.scaling or 3,
                            gfxX = de.gfxX,
                            gfxY = de.gfxY
                        })
                    end
                end
                enemies = {}
                deathTimer = 0
                explosionTriggered = true
                setGameState("exploding")
                break
            end
        end
    end

    -- Screenshake timer for explosion and milestone
    if screenShake then
        t = t + dt
        scoreWobble = scoreWobble + 0.1 * dt
        scoreScaleFactor = scoreScaleFactor + 0.02
        if t >= shakeDuration then
            screenShake = nil
            scoreWobble = 0
            scoreScaleFactor = 2
            t = 0
        end
    end

    -- Exploding enemies logic
    if gameState == "exploding" then
        deathTimer = deathTimer + dt
        for _, e in ipairs(deadEnemies) do
            e.x = e.x + math.random(-200, 200) * dt
            e.y = e.y + math.random(-200, 200) * dt
            e.rot = e.rot + dt * math.random(5, 10)
        end
        if deathTimer >= deathDelay then
            setGameState("dead")
            deadEnemies = {}
        end
    end
end


function love.draw()
    if gameState == "menu" then
        for _, btn in ipairs(buttons) do
            -- Button rectangle
            love.graphics.setColor(btn.c[1], btn.c[2], btn.c[3]) -- button color
            love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 10, 10)
            
            -- Button text
            love.graphics.setColor(1, 1, 1)
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(btn.text)
            local textHeight = font:getHeight(btn.text)
            love.graphics.print(btn.text, btn.x + (btn.width - textWidth) / 2, btn.y + (btn.height - textHeight) / 2)
        end
        love.graphics.printf("Goober Game\nPress SPACE to Start", 0, windowY/2 - 40, windowX, "center")

    elseif gameState == "playing" then
        if screenShake then
            local dx = math.random(-magnitude, magnitude)
            local dy = math.random(-magnitude, magnitude)
            love.graphics.translate(dx, dy)
        end
        love.graphics.draw(bg, 0, 0, 0, 3, 2)
        playerObj:draw()
        for _, e in ipairs(enemies) do
            e:draw()
        end
        love.graphics.print(score, 20, 20, scoreWobble, scoreScaleFactor, scoreScaleFactor)

    elseif gameState == "exploding" then
        love.graphics.draw(bg, 0, 0, 0, 3, 2)
        playerObj:draw()
        for _, e in ipairs(deadEnemies) do
            love.graphics.draw(
                e.gfx,
                e.x, e.y,
                e.rot,
                e.scaling, e.scaling,
                e.gfxX, e.gfxY
            )
        end

    elseif gameState == "dead" then
        love.graphics.printf("You Died!\nPress R to Restart\nPress M for Menu", 0, windowY/2 - 40, windowX, "center")
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if gameState == "menu" and key == "space" then
        resetGame()
        setGameState("playing")

    elseif gameState == "dead" then
        if key == "r" then
            resetGame()
            setGameState("playing")
        elseif key == "m" then
            setGameState("menu")
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        for _, btn in ipairs(buttons) do
            if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
                btn.onClick()
            end
        end
    end
end
-- Requires
local player = require("entity.player")
local enemy = require("entity.goobers")
local bullets = require("entity.bullet")
local tick = require("tick")
require("lib")

-- Seed and graphics
math.randomseed(os.time())
love.graphics.setDefaultFilter("nearest", "nearest")

-- Game variables
local music = nil
local gameState = "menu" -- "menu", "playing", "dead", "exploding"
local screenShake = nil
local t, shakeDuration, magnitude = 0, 0.7, 5
local gameTimer = 0
local windowX, windowY = love.graphics.getPixelDimensions()
local playerGfx = love.graphics.newImage("gfx/player.png")
local enemyGfx = love.graphics.newImage("gfx/enemy.png")
local bg = love.graphics.newImage("gfx/bg.png")
local scaleFactor = 2
local score = 0
local scoreWobble = 0
local scoreScaleFactor = 2
local spawningenemies = false

-- Explosion & death
local deathDelay = 2
local deathTimer = 0
local deadEnemies = {}

-- Player and enemy tables
local playerObj = nil
local enemies = {}

-- Music and difficulty
local musicOptions = {
    easy = "sfx/easy.mp3",
    medium = "sfx/medium.mp3",
    hard = "sfx/hard.ogg"
}

local diffs = {
    easy = { baseLerp = 0.04, maxEnemies = 3, lifetime = 210 },
    medium = { baseLerp = 0.055, maxEnemies = 4, lifetime = 140 },
    hard = { baseLerp = 0.075, maxEnemies = 5, lifetime = 80 }
}

local diffConfig = { baseLerp = 0, maxEnemies = 0, lifetime = 0 }

-- Buttons
local buttons = {
    {text="Easy", x=20, y=20, width=200, height=150, c={0.15,0.85,0.15}, onClick=function()
        for k,v in pairs(diffs.easy) do diffConfig[k]=v end
        music = love.audio.newSource(musicOptions.easy, "stream")
    end},
    {text="Medium", x=20, y=190, width=200, height=150, c={0.15,0.15,0.85}, onClick=function()
        for k,v in pairs(diffs.medium) do diffConfig[k]=v end
        music = love.audio.newSource(musicOptions.medium, "stream")
    end},
    {text="Hard", x=20, y=360, width=200, height=150, c={0.85,0.15,0.15}, onClick=function()
        for k,v in pairs(diffs.hard) do diffConfig[k]=v end
        music = love.audio.newSource(musicOptions.hard, "stream")
    end}
}

-- Love load
function love.load()
    tick.framerate = 60
    playerObj = player:new(10, 10, playerGfx)
    enemies = {}
    music = love.audio.newSource(musicOptions.easy, "stream")
    love.audio.setVolume(0.2)
    music:setLooping(true)
end

-- Game state
local function setGameState(state)
    gameState = state
    if state == "playing" then
        if music then music:stop(); music:play() end
    else
        if music then music:stop() end
    end
end

local function resetGame()
    gameTimer = 0
    spawningenemies = false
    score = 0
    enemies = {}
    playerObj = player:new(10, 10, playerGfx)
end

-- Love update
function love.update(dt)
    -- Screenshake trigger
    if score % 500 == 0 and score > 0 then
        screenShake = true
    end

    if gameState == "playing" then
        gameTimer = gameTimer + 1
        score = gameTimer

        -- Mouse follow
        local mx, my = love.mouse.getPosition()
        playerObj.x = mx
        playerObj.y = my

        -- Spawn enemies
        if gameTimer == 60 then spawningenemies = true end
        if spawningenemies and #enemies < diffConfig.maxEnemies then
            table.insert(enemies, enemy:new(
                math.random(1, windowX),
                math.random(1, windowY),
                playerObj.x,
                playerObj.y,
                nil, nil,
                enemyGfx,
                diffConfig.baseLerp,
                diffConfig.lifetime
            ))
        end

        -- Update enemies
        local explosionTriggered = false
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            if not e then break end

            if e:move(dt, playerObj.x, playerObj.y) then
                table.remove(enemies, i)
            end

            local collided = e:handleEnemyDeath(
                playerObj.x, playerObj.y,
                playerGfx:getWidth() * scaleFactor,
                enemyGfx:getWidth() * scaleFactor
            )

            if collided and not explosionTriggered then
                -- Explode all enemies
                deadEnemies = {}
                for j=1,#enemies do
                    local de = enemies[j]
                    if de then
                        table.insert(deadEnemies, {
                            x=de.x, y=de.y, gfx=de.gfx,
                            rot=0, scaling=de.scaling or 3,
                            gfxX=de.gfxX, gfxY=de.gfxY
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

        -- Player auto-fire at enemies
        playerObj:update(dt, enemies)
    end

    -- Screenshake logic
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
            e.rot = e.rot + dt * math.random(5,10)
        end
        if deathTimer >= deathDelay then
            setGameState("dead")
            deadEnemies = {}
        end
    end
end

-- Love draw
function love.draw()
    if gameState == "menu" then
        for _, btn in ipairs(buttons) do
            love.graphics.setColor(btn.c[1], btn.c[2], btn.c[3])
            love.graphics.rectangle("fill", btn.x, btn.y, btn.width, btn.height, 10,10)
            love.graphics.setColor(1,1,1)
            local font = love.graphics.getFont()
            local tw = font:getWidth(btn.text)
            local th = font:getHeight(btn.text)
            love.graphics.print(btn.text, btn.x + (btn.width-tw)/2, btn.y + (btn.height-th)/2)
        end
        love.graphics.printf("Goober Game\nPress SPACE to Start", 0, windowY/2 - 40, windowX, "center")

    elseif gameState == "playing" then
        if screenShake then
            love.graphics.translate(math.random(-magnitude,magnitude), math.random(-magnitude,magnitude))
        end
        love.graphics.draw(bg,0,0,0,3,2)
        playerObj:draw()
        for _, e in ipairs(enemies) do e:draw() end
        love.graphics.print(score, 20,20,scoreWobble,scoreScaleFactor,scoreScaleFactor)

    elseif gameState == "exploding" then
        love.graphics.draw(bg,0,0,0,3,2)
        playerObj:draw()
        for _, e in ipairs(deadEnemies) do
            love.graphics.draw(e.gfx, e.x, e.y, e.rot, e.scaling, e.scaling, e.gfxX, e.gfxY)
        end

    elseif gameState == "dead" then
        love.graphics.printf("You Died!\nPress R to Restart\nPress M for Menu", 0, windowY/2-40, windowX, "center")
    end
end

-- Key pressed
function love.keypressed(key)
    if key == "escape" then love.event.quit() end
    if gameState=="menu" and key=="space" then
        resetGame()
        setGameState("playing")
    elseif gameState=="dead" then
        if key=="r" then resetGame(); setGameState("playing")
        elseif key=="m" then setGameState("menu") end
    end
end

-- Mouse pressed
function love.mousepressed(x,y,button)
    if button==1 then
        for _,btn in ipairs(buttons) do
            if x>=btn.x and x<=btn.x+btn.width and y>=btn.y and y<=btn.y+btn.height then
                btn.onClick()
            end
        end
    end
end

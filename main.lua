UtilityFunction = require("UtilityFunction") -- utility functions
Player = require("Player") -- player logic
Balls = require("Balls") -- ball logic
Timer = require("Libraries.timer") -- timer library
local upgradesUI = require("upgradesUI") -- upgrade UI logic
local permanentUpgrades = require("permanentUpgrades") -- permanent upgrades UI
shaders = require("shaders") -- shader logic
suit = require("Libraries.Suit") -- UI library
tween = require("Libraries.tween") -- tweening library
VFX = require("VFX") -- VFX library
local KeySys = require("KeywordSystem") -- Keyword system for text parsing
local Explosion = require("particleSystems.explosion") -- Explosion particle system

local startingItemName = nil
-- Game states
GameState = {
    MENU = "menu",
    START_SELECT = "start_select",
    PLAYING = "playing",
    PAUSED = "paused",
    SETTINGS = "settings",
    UPGRADES = "upgrades",
    TUTORIAL = "tutorial",
    VICTORY = "victory"
}
currentGameState = GameState.MENU

-- Add this variable to store the player's choice
local startingChoice = nil

--screen dimensions
statsWidth = 450 -- Width of the stats area
screenWidth = 1020 + statsWidth
screenHeight = 1000
backgroundIntensity = 0

playRate = 1 -- Set the playback rate to 1 (normal speed)
gameCanvas = nil

local baseSpawnRate = 1.0 -- Base time between spawns in seconds
local minSpawnRate = 0.1 -- Minimum time between spawns
local spawnAcceleration = 0.01 -- How much faster spawning gets per second
local currentSpawnRate = 1.0 -- Current time between spawns
local gameStartTime = 0

function resetGame()
    -- Reset game state
    currentGameState = GameState.MENU
    
    -- Reset game timers
    gameStartTime = 0
    gameTime = 0
    frozenTime = 0
    lastFreezeTime = 0
    startTime = -10
    
    -- Reset gameplay variables
    playRate = 1
    backgroundIntensity = 0
    spawnTimer = 0
    currentSpawnRate = 1.0
    currentRowPopulation = 1
    damageThisFrame = 0
    
    -- Reset screen effects
    screenOffset = {x = 0, y = 0}
    
    -- Reset paddle to default position and size
    paddle = {
        x = screenWidth / 2 - 100,
        y = screenHeight - 400,
        width = 200 + (Player.permanentUpgrades.paddleSize or 0), -- Base width + size upgrade
        widthMult = 1,
        height = 20,
        speed = 400 + (Player.permanentUpgrades.paddleSpeed or 0),
        currrentSpeedX = 0,
        speedMult = 1
    }
    
    -- Clear any existing bricks
    bricks = {}
    
    -- Reset all Player stats and values
    Player.reset()
    
    -- Reset balls
    for i = #Balls, 1, -1 do
        Balls[i] = nil
    end
    Balls.clearUnlockedBallTypes()
    Balls.initialize()


    -- Reset timers
    Timer.clear()
    
    -- Reset tweens
    if Tweens then
        for i = #Tweens, 1, -1 do
            table.remove(Tweens, i)
        end
    end

    -- Unfreeze the game
    UtilityFunction.freeze = false
    
    -- Remove any existing animations or effects
    if explosions then
        for i = #explosions, 1, -1 do
            table.remove(explosions, i)
        end
    end

    resetDamageNumbers()

    initializeBricks()

    --Balls.addBall(startingItemName)

    resetAnimations()

    brickPieces = {} -- Reset brick pieces
end

local function loadAssets()
    --load images
    auraImg = love.graphics.newImage("assets/sprites/aura.png")
    brickImg = love.graphics.newImage("assets/sprites/brick.png")
    heartImg = love.graphics.newImage("assets/sprites/heart.png") -- Heart image for health
    muzzleFlashImg = love.graphics.newImage("assets/sprites/muzzleFlash.png")
    rocketImg = love.graphics.newImage("assets/sprites/rocket.png")
    turretImg = love.graphics.newImage("assets/sprites/turret.png")
    brickPiece1Img = love.graphics.newImage("assets/sprites/brickPiece1.png")
    brickPiece2Img = love.graphics.newImage("assets/sprites/brickPiece2.png")
    brickPiece3Img = love.graphics.newImage("assets/sprites/brickPiece3.png")
        -- UI
    uiLabelImg = love.graphics.newImage("assets/sprites/UI/ballUI backgroundTop.png")
    uiSmallWindowImg = love.graphics.newImage("assets/sprites/UI/newBallBackground.png")
    uiWindowImg = love.graphics.newImage("assets/sprites/UI/ballBackground.png")
    uiBigWindowImg = love.graphics.newImage("assets/sprites/UI/ballBackground_20.png")
        --Icons
    iconsImg = {
        amount = love.graphics.newImage("assets/sprites/UI/icons/amount.png"),
        ammo = love.graphics.newImage("assets/sprites/UI/icons/ammo.png"),
        damage = love.graphics.newImage("assets/sprites/UI/icons/damage.png"),
        cooldown = love.graphics.newImage("assets/sprites/UI/icons/cooldown.png"),
        fireRate = love.graphics.newImage("assets/sprites/UI/icons/fireRate.png"),
        speed = love.graphics.newImage("assets/sprites/UI/icons/speed.png"),
        range = love.graphics.newImage("assets/sprites/UI/icons/range.png"),
        ballDamage = love.graphics.newImage("assets/sprites/UI/icons/ballDamage.png"),
        paddleSize = love.graphics.newImage("assets/sprites/UI/icons/paddleSize.png"),
        bulletDamage = love.graphics.newImage("assets/sprites/UI/icons/bulletDamage.png"),
        income = love.graphics.newImage("assets/sprites/UI/icons/income.png"),
        health = love.graphics.newImage("assets/sprites/UI/icons/health.png"),
    }

    -- load sounds
    backgroundMusic = love.audio.newSource("assets/SFX/game song.mp3", "static")
    brickHitSFX = love.audio.newSource("assets/SFX/brickBoop.mp3", "static")
    paddleBoopSFX = love.audio.newSource("assets/SFX/paddleBoop.mp3", "static")
    wallBoopSFX = love.audio.newSource("assets/SFX/wallBoop.mp3", "static")
    explosionSFX = love.audio.newSource("assets/SFX/explosion.mp3", "static") -- Add explosion sound if available
    brickDeathSFX = love.audio.newSource("assets/SFX/brickDeath.mp3", "static")
    gunShootSFX = love.audio.newSource("assets/SFX/gunShoot.mp3", "static") -- Add gun shoot sound if available

    -- load shaders
    backgroundShader = love.graphics.newShader("Shaders/background.glsl")
    glowShader = love.graphics.newShader("Shaders/glow.glsl")

    -- load spriteSheets
    loadingVFX = love.graphics.newImage("assets/sprites/UI/loading.png")
    impactVFX = love.graphics.newImage("assets/sprites/VFX/Impact.png")
    smokeVFX = love.graphics.newImage("assets/sprites/VFX/smoke.png")
    sparkVFX = love.graphics.newImage("assets/sprites/VFX/spark.png")
    lightningVFX = love.graphics.newImage("assets/sprites/VFX/spark.png")
    chainLightningVFX = love.graphics.newImage("assets/sprites/VFX/chainLightning.png")
    explosionVFX = love.graphics.newImage("assets/sprites/VFX/explosion.png")
    fireballVFX = love.graphics.newImage("assets/sprites/VFX/fireball.png")
    sawBladesVFX = love.graphics.newImage("assets/sprites/VFX/sawBlades.png")
    fireVFX = love.graphics.newImage("assets/sprites/VFX/fire.png")
    flamethrowerStartVFX = love.graphics.newImage("assets/sprites/VFX/flamethrowerStart.png")
    flamethrowerLoopVFX = love.graphics.newImage("assets/sprites/VFX/flamethrowerLoop.png")
    flamethrowerEndVFX = love.graphics.newImage("assets/sprites/VFX/flamethrowerEnd.png")

    Player.loadJsonValues()
end

dmgVFXOn = true

local function getMaxBrickHealth()
    -- Scale max health from 1 to 26 over 5 minutes
    local timeSinceStart = love.timer.getTime() - gameStartTime
    local maxHealth = math.floor(mapRangeClamped(timeSinceStart, 0, 300, 1, 26))
    return maxHealth
end

local function spawnBrick()
    local x = statsWidth + math.random() * (screenWidth - statsWidth * 2 - brickWidth) + 20
    local maxHealth = getMaxBrickHealth()
    local health = math.random(1, maxHealth)
    local brickColor = getBrickColor(health)
    
    table.insert(bricks, {
        id = #bricks + 1,
        x = x,
        y = -brickHeight - 5, -- Spawn just above screen
        drawOffsetX = 0,
        drawOffsetY = 0,
        drawOffsetRot = 0,
        drawScale = 1,
        width = brickWidth,
        height = brickHeight,
        destroyed = false,
        health = health,
        color = {brickColor[1], brickColor[2], brickColor[3], 1},
        hitLastFrame = false
    })
end

local function addMoreBricks(dt)
    -- Update spawn rate
    currentSpawnRate = math.max(minSpawnRate, baseSpawnRate - spawnAcceleration * (love.timer.getTime() - gameStartTime))
    
    -- Update spawn timer
    spawnTimer = spawnTimer + dt
    
    -- Spawn new brick if it's time
    if spawnTimer >= currentSpawnRate then
        spawnTimer = spawnTimer - currentSpawnRate
        spawnBrick()
    end
end

local bossWidth, bossHeight = 1000, 600
local bossHealth = 2500
local bossSpawned = false
local brickId = 1
local function spawnBoss()
    -- Center the boss brick at the top
    print("Spawning boss brick")
    local bossX = screenWidth / 2 - bossWidth / 2
    local bossY = -bossHeight
    local brickColor = getBrickColor(bossHealth, false, true)
    table.insert(bricks, {
        type = "boss",
        id = brickId,
        x = bossX,
        y = bossY,
        drawOffsetX = 0,
        drawOffsetY = 0,
        drawOffsetRot = 0,
        drawScale = 1,
        width = bossWidth,
        height = bossHeight,
        destroyed = false,
        health = bossHealth,
        color = {brickColor[1], brickColor[2], brickColor[3], 1},
        hitLastFrame = false
    })
    brickId = brickId + 1
end

local unavailableXpos = {}
local currentRow = 1
local nextRowDebuff = 0
local function generateRow(brickCount, yPos)
    brickCount = brickCount - nextRowDebuff
    nextRowDebuff = 0 -- Reset next row debuff for the next row
    --[[if brickCount >= 1000 and not bossSpawned then
        print("SPAWN BOSS MOUAHAHAHAHAA")
        spawnBoss()
        bossSpawned = true
    end]]
    local row = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    local rowOffset = 0--mapRangeClamped(math.random(0,10),0,10, 0, brickWidth)
    for i = 1, brickCount do
        local bruh = true
        local n = 1
        while bruh do
            n = math.random(12)
            if not unavailableXpos[n] then 
                bruh = false
            end
        end
        row[n] = row[n] + 1
    end
    unavailableXpos = {}
    local bigBrickLocations = {}
    for xPos, brickHealth in ipairs(row) do
        if brickHealth > 0 then
            if (not bigBrickLocations[xPos-1]) then
                if xPos < 11 and math.random(1, 100) < math.floor(mapRangeClamped(brickCount, 1, 1000, 0, 25)) and row[xPos+1] > 0 then
                    if (brickHealth + row[xPos+1]) * 2 >= 50 then
                        bigBrickLocations[xPos] = true
                        unavailableXpos[xPos] = true
                        unavailableXpos[xPos+1] = true
                        local bigBrickHealth = (brickHealth + row[xPos+1])*2
                        local brickColor = getBrickColor(bigBrickHealth, true)
                        nextRowDebuff = brickHealth + row[xPos+1] -- Set the next row debuff to the health of the big brick
                        table.insert(bricks, {
                            type = "big",
                            id = brickId,
                            x = statsWidth + (xPos - 1) * (brickWidth + brickSpacing) + 5 + rowOffset,
                            y = yPos - (brickHeight + brickSpacing/2),
                            drawOffsetX = 0,
                            drawOffsetY = 0,
                            drawOffsetRot = 0,
                            drawScale = 1,
                            width = brickWidth*2,
                            height = brickHeight*2,
                            destroyed = false,
                            health = bigBrickHealth,
                            colorHealth = bigBrickHealth / 5, -- store the divided value for color
                            color = {brickColor[1], brickColor[2], brickColor[3], 1},
                            hitLastFrame = false
                        })
                        brickId = brickId + 1
                        nextRowDebuff = brickHealth + row[xPos+1]
                    end
                else
                    local brickColor = getBrickColor(brickHealth)
                    table.insert(bricks, {
                        type = "small",
                        id = brickId,
                        x = statsWidth + (xPos - 1) * (brickWidth + brickSpacing) + 5 + rowOffset,
                        y = yPos,
                        drawOffsetX = 0,
                        drawOffsetY = 0,
                        drawOffsetRot = 0,
                        drawScale = 1,
                        width = brickWidth,
                        height = brickHeight,
                        destroyed = false,
                        health = brickHealth,
                        color = {brickColor[1], brickColor[2], brickColor[3], 1},
                        hitLastFrame = false
                    })
                    brickId = brickId + 1
                end
            end
        end
    end
    currentRow = currentRow + 1
    return row
end

local spawnBossNextRow = false
--local currentRowPopulation
local function addMoreBricks()
    if bricks[#bricks] then
        if bricks[#bricks].y > -50 then
            print("spawning more bricks")
            for i=1 , 10 do
                generateRow(currentRowPopulation, i * -(brickHeight + brickSpacing) - 50) --generate 100 scaling rows of bricks
                currentRowPopulation = currentRowPopulation + 1 + math.floor(currentRow/20)
                if spawnBossNextRow and not bossSpawned then
                    spawnBoss()
                    bossSpawned = true
                    currentRowPopulation = 500
                end
            end
            return
        else 
            return
        end--else print("bricks are too high to spawn more") end
    end
end

function getBrickColor(health, bigBrick, boss, colorHealth)
    bigBrick = bigBrick or false
    boss = boss or false
    -- Use colorHealth if provided, otherwise use health (for small bricks)
    local colorValue = colorHealth or health
    if bigBrick then
        colorValue = (health + 4) / 5  -- Scale down health for big bricks
    end
    if boss then
        colorValue = (health + 124) / 125
    end
    -- Use a square root function to slow down the color change at higher health values
    local scaledHealth = math.sqrt(colorValue / 200) * 200
    local hue = 100 - (scaledHealth - 1) * (360/100)
    if hue < 0 then hue = hue + 360 end
    local saturation = math.max(0, 1 - math.sqrt((colorValue - 1) / 100))
    local lightness = 0.5
    local alpha = 1
    return {HslaToRgba(hue, saturation, lightness, alpha)}
end

function initializeBricks()
    -- Bricks
    bricks = {}
    brickWidth = 75
    brickHeight = 30
    brickSpacing = 10 -- Spacing between bricks
    rows = 10
    cols = 10
    brickSpeed = { value = 10 } -- Speed at which bricks move down (pixels per second)
    currentRowPopulation = 1 -- Number of bricks in the first row

    -- Generate bricks
    for i = 0, rows - 1 do
        generateRow(currentRowPopulation, i * -(brickHeight + brickSpacing)) --generate 100 scaling rows of bricks
        currentRowPopulation = currentRowPopulation + 1 + math.floor(currentRowPopulation/25)
    end

    --check for adding more bricks every 0.5 seconds
    Timer.every(0.5, function() addMoreBricks() end)
end

function initializeGameState()
    -- Reset timers
    gameStartTime = love.timer.getTime()
    gameTime = 0
    frozenTime = 0
    lastFreezeTime = 0

    -- Initialize bricks FIRST
    initializeBricks()
    
    -- Then initialize Balls
    Balls.initialize()
end

function love.load()
    dress = suit.new()

    loadAssets() -- Load assets

    KeywordSystem = KeySys.new()
    KeywordSystem:loadKeywordImages()

    -- Load the MP3 file
    playSoundEffect(backgroundMusic, 0.5, 1, true, false) -- Play the background music
    brickFont = love.graphics.newFont(14)    -- Get screen dimensions
    screenWidth, screenHeight = love.graphics.getDimensions()

    gameCanvas = love.graphics.newCanvas(screenWidth, screenHeight)
    uiCanvas = love.graphics.newCanvas(screenWidth, screenHeight)

    -- Render glow canvases at half resolution for performance
    local glowWidth, glowHeight = math.floor(screenWidth / 2), math.floor(screenHeight / 2)
    glowCanvas = {
        weak = love.graphics.newCanvas(glowWidth, glowHeight, {
            format = "rgba8",
            msaa = 1
        }),
        normal = love.graphics.newCanvas(glowWidth, glowHeight, {
            format = "rgba8",
            msaa = 1
        }),
        bright = love.graphics.newCanvas(glowWidth, glowHeight, {
            format = "rgba8",
            msaa = 1
        })
    }

    -- Create a new canvas for the shader overlay
    shaderOverlayCanvas = love.graphics.newCanvas(screenWidth, screenHeight)

    -- Create temporary canvas for blur
    blurTempCanvas = love.graphics.newCanvas(glowWidth, glowHeight, {format = "rgba8", msaa = 1})

    love.window.setTitle("Brick Breaker")    -- Reset game start time and frozen time tracking

    -- Paddle
    paddle = {
        x = screenWidth / 2 - 50,
        y = screenHeight/2,
        width = 200 + (Player.permanentUpgrades.paddleSize or 0), -- Base width + size upgrade
        widthMult = 1,
        height = 20,    
        speed = 400 + (Player.permanentUpgrades.paddleSpeed or 0), -- Base speed + speed upgrade
        currrentSpeedX = 0,
        speedMult = 1
    }

    local data = loadGameData()
    Player.permanentUpgrades = data.permanentUpgrades
    Player.permanentUpgradePrices = data.permanentUpgradePrices
    Player.gold = data.gold
    Player.startingMoney = data.startingMoney
end

function getHighestBrickY()
    -- Defensive: ensure bricks is always a table
    if type(bricks) ~= "table" then bricks = {} end
    local highestY = -math.huge  -- Start with lowest possible number
    for _, brick in ipairs(bricks) do
        if not brick.destroyed and brick.y > highestY then
            highestY = brick.y
        end
    end
    return highestY
end

function getBrickSpeedByTime()
    -- Scale speed from 0.5 to 5.0 over 10 minutes
    local timeSinceStart = love.timer.getTime() - gameStartTime
    return mapRangeClamped(timeSinceStart, 0, 450, 0.35, 1.0)
end

local function getBrickSpeedMult() 
    -- Get the position-based multiplier
    local posMult = 1
    for i, brick in ipairs(bricks) do
        if not brick.destroyed then
            posMult = mapRangeClamped(brick.y, 100, (screenHeight/2 - brick.height), 10, 1)
            break
        end
    end
    if #bricks == 0 then
        return 1
    end
    
    -- Don't apply time-based acceleration if game is frozen
    if UtilityFunction.freeze then
        return posMult
    end
    
    -- Combine with time-based multiplier
    return posMult * getBrickSpeedByTime()
end

local function moveBricksDown(dt)
    if UtilityFunction.freeze then
        return -- Don't move bricks at all when frozen
    end
    
    local currentTime = love.timer.getTime()
    local isInHitState = (currentTime - Player.lastHitTime) < 2.0 -- Check if within 2 seconds of hit
    
    if isInHitState then
        -- Use constant speed of -300 during hit state
        for _, brick in ipairs(bricks) do
            if not brick.destroyed then
                if brick.type == "boss" then
                    -- Boss bricks do NOT get pushed back when player is hit
                    -- Do nothing
                else
                    brick.y = brick.y - 300 * dt
                end
            end
        end
    else
        -- Normal speed calculation
        local speedMult = getBrickSpeedMult() -- Get the combined speed multiplier
        for _, brick in ipairs(bricks) do
            if not brick.destroyed then
                if brick.type == "boss" then
                    brick.y = brick.y + brickSpeed.value * dt * speedMult * 0.5
                else
                    brick.y = brick.y + brickSpeed.value * dt * speedMult
                end
            end
        end
    end
end

local function reduceBackgroundBrightness()
    -- Reduce background brightness over time, faster at higher intensities
    local reductionRate = 0.01 * (backgroundIntensity * 2) -- Scales from 0.01 to 0.03 based on intensity
    backgroundIntensity = math.max(0, backgroundIntensity - reductionRate)
    backgroundShader:send("intensity", backgroundIntensity)
end

screenOffset = {x=0,y=0}
local startTime = -10
local gameTime = 0  -- Tracks actual elapsed gameplay time

local function brickPiecesUpdate(dt)
    for _, brickpiece in ipairs(brickPieces) do
        if not brickpiece.destroyed then
            brickpiece.y = brickpiece.y + brickpiece.speedY * dt
            brickpiece.x = brickpiece.x + brickpiece.speedX * dt
            brickpiece.speedY = brickpiece.speedY + 500 * dt -- Apply gravity
            if brickpiece.y > screenHeight + 50 then
                brickpiece.destroyed = true -- Remove piece if it goes off screen
            end
        end
    end
end

-- Generic garbage collection for dynamic object tables
local function cleanTable(tbl, isDeadFunc)
    local i = 1
    while i <= #tbl do
        if isDeadFunc(tbl[i]) then
            table.remove(tbl, i)
        else
            i = i + 1
        end
    end
end

local function garbageCollectDynamicObjects()
    if brickPieces then
        cleanTable(brickPieces, function(obj) return obj.destroyed or obj.dead or obj.remove or obj.toRemove end)
    end
    if fireballs then
        cleanTable(fireballs, function(obj) return obj.destroyed or obj.dead or obj.remove or obj.toRemove end)
    end
    if darts then
        cleanTable(darts, function(obj) return obj.destroyed or obj.dead or obj.remove or obj.toRemove end)
    end
    if deadBullets then
        cleanTable(deadBullets, function(obj) return obj.destroyed or obj.dead or obj.remove or obj.toRemove end)
    end
    -- Add more as needed for other dynamic object tables
end

brickKilledThisFrame = false
local damageCooldown = 0 -- Cooldown for damage visuals
local function gameFixedUpdate(dt)
    
    dt = 1/60 -- Fixed delta time for consistent updates
    dt = dt * 1.75
    --send info to background shader
    backgroundShader:send("time", love.timer.getTime())                   
    backgroundShader:send("resolution", {screenWidth, screenHeight})
    backgroundShader:send("brightness", backgroundIntensity)
    reduceBackgroundBrightness()
    local backgroundIntensity = Player.score <= 100 and mapRangeClamped(Player.score,1,100, 0.0, 0.15) or (Player.score <= 5000 and mapRangeClamped(Player.score, 100, 5000, 0.15, 0.5) or mapRangeClamped(Player.score, 5000, 100000, 0.5, 1.0))

    if currentGameState == GameState.PAUSED then
        return -- Don't update game logic while paused
    end
    
    if currentGameState == GameState.PLAYING then
        KeywordSystem:update() -- Update the keyword system
        -- overwrites backgroundIntensity if using debugging window
        if shouldDrawDebug then
            backgroundIntensity = VFX.backgroundIntensityOverwrite 
        end

        if currentScreenShakeIntensity > 0 then
            screenShakeIntensityDeprecation(dt)
        end

        brickPiecesUpdate(dt) -- Update brick pieces
        -- Garbage collect dynamic objects
        garbageCollectDynamicObjects()
        backgroundShader:send("intensity", backgroundIntensity)
        if startTime == -10 then
            startTime = love.timer.getTime()+0.5
        end
        local sineShaderIntensity = 0.3 -- Default base intensity


        -- Don't update game time when level up shop is open
        if Player.levelingUp then
            if lastFreezeTime == 0 then
                lastFreezeTime = love.timer.getTime()
            end
            dt = 0
        else
            -- If we just closed the shop, update the frozen time
            if lastFreezeTime then
                if lastFreezeTime > 0 then
                    frozenTime = frozenTime + (love.timer.getTime() - lastFreezeTime)
                    lastFreezeTime = 0
                end
            end
        end

        dt = dt * playRate -- Adjust the delta time based on the playback rate
        dt = dt * 0.4 -- ralenti le jeu a la bonne vitesse
        if UtilityFunction.freeze then
            dt = 0 -- Freeze the game if UtilityFunction.freeze is true
        end
        Timer.update(dt) -- Update the timer

        local function updateGameTime(dt)
            if not UtilityFunction.freeze and not Player.levelingUp then
                gameTime = gameTime + dt * playRate
            end
        end
        
        updateGameTime(dt)

        -- checks if game is frozen
        if not Player.levelingUp and not UtilityFunction.freeze then
            -- Paddle movement
            local moveX, moveY = 0, 0
            if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
                moveX = moveX - 1
            end
            if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
                moveX = moveX + 1
            end
            moveY = moveY - 0.2

            paddle.x = paddle.x + moveX * paddle.speed * paddle.speedMult * dt
            paddle.y = paddle.y + moveY * paddle.speed * paddle.speedMult * dt

            -- Optionally update currentSpeedX/currentSpeedY for other logic
            paddle.currentSpeedX = moveX * paddle.speed * paddle.speedMult
            paddle.currentSpeedY = moveY * paddle.speed * paddle.speedMult

            -- Keep paddle within screen bounds
            paddle.x = math.max(statsWidth - (paddle.width/2) + 65, math.min(screenWidth - statsWidth - paddle.width + (paddle.width/2) - 65, paddle.x))
            paddle.y = math.max(math.max(getHighestBrickY() + brickHeight*6, screenHeight/2 + 100), math.min(screenHeight - paddle.height - 10, paddle.y))

            -- Update Balls
            Balls.update(dt, paddle, bricks, Player)

            -- Update explosions
            Explosion.update(dt)
            
            -- Move bricks down
            moveBricksDown(dt)

            boomUpdate(dt) -- Update explosion for damage

            updateAllTweens(dt) -- Update all tweens

            Player.update(dt) -- Update player logic

            updateAnimations(dt) -- Update animations

            if damageCooldown > 0 then
                damageCooldown = damageCooldown - dt -- Reduce damage cooldown
            end
            
            if brickKilledThisFrame and damageCooldown <= 0 then
                -- Play brick hit sound effect
                playSoundEffect(brickDeathSFX, 0.25, 1, false, true)
            end
            damageThisFrame = damageThisFrame or 0 -- Reset damage this frame
            if damageThisFrame > 0 and damageCooldown <= 0 then
                damageScreenVisuals(mapRangeClamped(damageThisFrame,1,20,0.25, 0.5), damageThisFrame)
                playSoundEffect(brickHitSFX, mapRangeClamped(damageThisFrame, 1,10, 0.4,1.0) * 0.8, mapRangeClamped(damageThisFrame,1,20,0.5,1), false, true)
                damageCooldown = 0.05 -- Set cooldown for damage visuals
                damageThisFrame = 0 -- Reset damage this frame
            end
            brickKilledThisFrame = false -- Reset brick hit state for the next frame
            VFX.update(dt) -- Update VFX
        end
    end
    
end

local accumulator = 0
local fixed_dt = 1/60
function love.update(dt)
    accumulator = accumulator + dt
    while accumulator >= fixed_dt do
        gameFixedUpdate(fixed_dt) -- Your game logic here, using fixed_dt
        accumulator = accumulator - fixed_dt
    end
end

-- Menu settings
local menuFont
local buttonWidth = 400
local buttonHeight = 75
local buttonSpacing = 100
function drawMenu()
    -- Calculate center positions
    local centerX = screenWidth / 2 - buttonWidth / 2
    local startY = screenHeight / 2 - (buttonHeight * 3 + buttonSpacing * 2) / 2
    
    -- Draw title
    setFont(48)
    local title = "BRICK BREAKER"
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(title, screenWidth/2 - titleWidth/2, startY - 100)

    -- Play button
    local buttonID = generateNextButtonID()
    if suit.Button("Play", {id=buttonID}, centerX, startY, buttonWidth, buttonHeight).hit then
        currentGameState = GameState.START_SELECT -- Go to selection screen
    end

    -- Tutorial button
    buttonID = generateNextButtonID()
    if suit.Button("Tutorial", {id=buttonID}, centerX, startY + buttonHeight + buttonSpacing, buttonWidth, buttonHeight).hit then
        currentGameState = GameState.TUTORIAL
    end

    -- Settings button
    buttonID = generateNextButtonID()
    if suit.Button("Settings", {id=buttonID}, centerX, startY + (buttonHeight + buttonSpacing) * 2, buttonWidth, buttonHeight).hit then
        --currentGameState = GameState.SETTINGS
    end

    -- Upgrades button
    buttonID = generateNextButtonID()
    if suit.Button("Upgrades", {id=buttonID}, centerX, startY + (buttonHeight + buttonSpacing) * 3, buttonWidth, buttonHeight).hit then
        currentGameState = GameState.UPGRADES
        loadGameData() -- Load game data when entering upgrades screen
    end

    -- draw highscore
    suit.Label("Highscore: " .. formatNumber(Player.highScore), {align = "center"}, 100, 100)
end

local currentSelectedCoreID = 1
local currentStartingItemID = 1
local startingItemOrder = {"Ball", "Pistol", "Laser Beam", "Fireball"}
-- Add a new function for the starting item selection screen
local function drawStartSelect()
    local centerX = screenWidth / 2 - buttonWidth / 2
    local startY = screenHeight / 3
    setFont(36)
    love.graphics.setColor(1, 1, 1, 1)
    suit.Label("Choose your starting item", {align = "center"}, screenWidth / 2 - getTextSize("Choose your starting item") / 2, startY - 100)

    -- Dynamically build the list of unlocked starting items
    local startingItems = {}

    -- Always include Ball
    table.insert(startingItems, {name = "Ball", id = "start_Ball", label = "Ball"})
    if Player.unlockedStartingBalls then
        for _, itemName in ipairs(startingItemOrder) do
            if Player.unlockedStartingBalls[itemName] then
                table.insert(startingItems, {name = itemName, id = "start_"..itemName:gsub(" ", "_"), label = itemName})
            end
        end
    end

    -- Always include Nothing
    --table.insert(startingItems, {name = "Nothing", id = "start_Nothing", label = "Nothing"})

    -- Draw buttons for each starting item
    local btnY = startY
    local item = startingItems[currentStartingItemID]
    local btnBefore = suit.Button("Back", {id = "back_starting_item"}, centerX - 100 - 20, btnY, 125, buttonHeight)
    local btn = suit.Label(item.label, {id = item.id}, centerX, btnY, buttonWidth, buttonHeight)
    local btnNext = suit.Button("Next", {id = "next_starting_item"}, centerX + buttonWidth + 20, btnY, 125, buttonHeight)
    if btnNext.hit then
        currentStartingItemID = currentStartingItemID + 1
        if currentStartingItemID > #startingItems then
            currentStartingItemID = 1
        end
        item = startingItems[currentStartingItemID]
        while (item.label == "1" or item.label == "2" or item.label == "3") do
            currentStartingItemID = currentStartingItemID + 1
            if currentStartingItemID > #startingItems then
                currentStartingItemID = 1
            end
            item = startingItems[currentStartingItemID]
        end
    end
    if btnBefore.hit then
        currentStartingItemID = currentStartingItemID - 1
        if currentStartingItemID < 1 then
            currentStartingItemID = #startingItems
        end
        item = startingItems[currentStartingItemID]
        while (item.label == "1" or item.label == "2" or item.label == "3") do
            currentStartingItemID = currentStartingItemID - 1
            if currentStartingItemID < 1 then
                currentStartingItemID = #startingItems
            end
            item = startingItems[currentStartingItemID]
        end
    end
    --[[for i, item in ipairs(startingItems) do
        if not (item.label == "1" or item.label == "2" or item.label == "3") then
            local btn = suit.Button(item.label, {id = item.id}, centerX, btnY, buttonWidth, buttonHeight)
            if btn.hit then
                startingChoice = item.name
                startingItemName = item.name
                currentGameState = GameState.PLAYING
                initializeGameState()
                if item.name ~= "Nothing" then
                    Balls.addBall(item.name)
                end
            end
            btnY = btnY + buttonHeight + 40
        end
    end]]

    -- logic for choosing paddle core
    btnY = btnY + buttonHeight + 150
    setFont(36)
    suit.Label("Choose your paddle core", {align = "center"}, screenWidth / 2 - getTextSize("Choose your paddle core") / 2, btnY - 80)
    local paddleCores = {}
    for _, core in ipairs(Player.availableCores) do
        local coreName = core.name -- Use core name if available, otherwise use the core itself
        if Player.paddleCores[coreName] then
            table.insert(paddleCores, coreName)
        end
    end
    local currentSelectedCore = paddleCores[currentSelectedCoreID]
    if not currentSelectedCoreID then currentSelectedCoreID = 1 end
    if not currentSelectedCore then currentSelectedCore = (paddleCores[currentSelectedCoreID] and paddleCores[currentSelectedCoreID].name or "Bouncy Core") end

    local core = paddleCores[currentSelectedCoreID]
    local btn2Before = suit.Button("Back", {id = "back_core"}, centerX - 100 - 20, btnY, 125, buttonHeight)
    local btn2 = suit.Label(currentSelectedCore, centerX, btnY, buttonWidth, buttonHeight)
    local btn2Next = suit.Button("Next", {id = "next_core"}, centerX + buttonWidth + 20, btnY, 125, buttonHeight)

    if btn2Next.hit then
        currentSelectedCoreID = currentSelectedCoreID + 1
        if currentSelectedCoreID > #paddleCores then
            currentSelectedCoreID = 1
        end
        core = paddleCores[currentSelectedCoreID]
        currentSelectedCore = core
    end
    if btn2Before.hit then
        currentSelectedCoreID = currentSelectedCoreID - 1
        if currentSelectedCoreID < 1 then
            currentSelectedCoreID = #paddleCores
        end
        core = paddleCores[currentSelectedCoreID]
        currentSelectedCore = core.name
    end

    -- Show the currently selected core
    setFont(25)
    -- Draw Play button centered under everything else
    local btnY = btnY + buttonHeight + 80
    local coreDescription = Player.coreDescriptions[core] and Player.coreDescriptions[core] or "No description available"
    suit.Label(coreDescription, {align = "center"}, screenWidth / 2 - 250, btnY - 50, 500, 100)
    local playBtnY = btnY + buttonHeight + 100
    setFont(40)
    local playBtn = suit.Button("Play", {id = "start_play"}, screenWidth / 2 - buttonWidth / 2, playBtnY, buttonWidth, buttonHeight)
    if playBtn.hit then
        startingChoice = item.name
        startingItemName = item.name
        Player.currentCore = currentSelectedCore -- Set the selected paddle core
        currentGameState = GameState.PLAYING
        initializeGameState()
        Player.bricksDestroyed = 0 -- Reset bricks destroyed count
        if item.name ~= "Nothing" then
            Balls.addBall(item.name)
        end
    end
end

function drawBricks()
    -- Only draw bricks that are on screen (culling)
    local screenTop = 0
    local screenBottom = screenHeight

    -- SpriteBatch for normal bricks
    local batch = love.graphics.newSpriteBatch(brickImg, #bricks)
    local batchData = {} -- Store info for HP text

    -- Draw boss bricks first (not batched)
    for _, brick in ipairs(bricks) do
        if brick.type == "boss" and not brick.destroyed and brick.y + brick.height > screenTop - 10 and brick.y < screenBottom + 10 then
            local color = brick.color or {1, 1, 1, 1}
            love.graphics.setColor(color)
            local scale = brick.drawScale or 1
            local scaleX = scale * (brick.width / brickImg:getWidth())
            local scaleY = scale * (brick.height / brickImg:getHeight())
            local centerX = brick.x + brick.width / 2 + brick.drawOffsetX
            local centerY = brick.y + brick.height / 2 + brick.drawOffsetY
            love.graphics.draw(
                brickImg,
                centerX,
                centerY,
                brick.drawOffsetRot,
                scaleX,
                scaleY,
                brickImg:getWidth() / 2,
                brickImg:getHeight() / 2
            )
            local hpText = tostring(brick.health or 0)
            setFont(15)
            local font = love.graphics.getFont()
            love.graphics.setColor(0, 0, 0, 1)
            love.graphics.print(hpText, centerX+1, centerY+1, 0, 1, 1, font:getWidth(hpText)/2, font:getHeight()/2)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(hpText, centerX, centerY, 0, 1, 1, font:getWidth(hpText)/2, font:getHeight()/2)
        end
    end

    -- Batch all other bricks
    for _, brick in ipairs(bricks) do
        if (not brick.type or brick.type ~= "boss") and not brick.destroyed and brick.y + brick.height > screenTop - 10 and brick.y < screenBottom + 10 then
            local color = brick.color or {1, 1, 1, 1}
            local scale = brick.drawScale or 1
            local scaleX = scale * (brick.width / brickImg:getWidth())
            local scaleY = scale * (brick.height / brickImg:getHeight())
            local centerX = brick.x + brick.width / 2 + brick.drawOffsetX
            local centerY = brick.y + brick.height / 2 + brick.drawOffsetY
            batch:setColor(color)
            local id = batch:add(
                centerX,
                centerY,
                brick.drawOffsetRot,
                scaleX,
                scaleY,
                brickImg:getWidth() / 2,
                brickImg:getHeight() / 2
            )
            table.insert(batchData, {centerX=centerX, centerY=centerY, health=brick.health})
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(batch)

    -- Draw HP text for batched bricks
    setFont(15)
    local font = love.graphics.getFont()
    for _, data in ipairs(batchData) do
        local hpText = tostring(data.health or 0)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(hpText, data.centerX+2, data.centerY+2, 0, 1.2, 1.2, font:getWidth(hpText)/2, font:getHeight()/2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(hpText, data.centerX, data.centerY, 0, 1.2, 1.2, font:getWidth(hpText)/2, font:getHeight()/2)
    end

    -- Draw brick pieces (not batched)
    for _, brickPiece in ipairs(brickPieces) do
        love.graphics.setColor(brickPiece.color)
        love.graphics.draw(brickPiece.img, brickPiece.x, brickPiece.y, 0, brickPiece.width / brickPiece.img:getWidth(), brickPiece.height / brickPiece.img:getHeight())
    end
end

local frozenTime = 0
local lastFreezeTime = 0

local hasSpawnedBoss = false
local function drawGameTimer()
    local countdownTime = 420 - gameTime
    if countdownTime <= 0 and not hasSpawnedBoss then
        spawnBossNextRow = true
        hasSpawnedBoss = true
    end
    local minutes = math.floor(countdownTime / 60)
    local seconds = math.floor(countdownTime % 60)
    local timeString = string.format("%02d:%02d", minutes, seconds)
    
    -- Draw timer
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(timeString)
    local x = screenWidth / 2 - 105
    local y = screenHeight - 175
    
    love.graphics.setColor(1, 1, 1, 1)
    setFont(80)
    if countdownTime > 0 then
        love.graphics.print(timeString, x, y)
    end
    if playRate ~= 1 then
        setFont(24)
        love.graphics.print(string.format(playRate) .. "X", x + textWidth + 10, y + 50)
    end
end

function drawPauseMenu()
    local centerX = screenWidth / 2 - buttonWidth / 2
    local startY = screenHeight / 2 - (buttonHeight * 2 + buttonSpacing * 2.5) / 2
    setFont(48)
    love.graphics.setColor(1, 1, 1, 1)
    local title = "Paused"
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, screenWidth/2 - titleWidth/2, startY - 100)

    setFont(36)
    local btnY = startY
    -- Resume button
    local resumeBtn = suit.Button("Resume", {id="pause_resume"}, centerX, btnY, buttonWidth, buttonHeight)
    if resumeBtn.hit then
        currentGameState = GameState.PLAYING
    end
    btnY = btnY + buttonHeight + 30
    -- Settings button (does nothing for now)
    local settingsBtn = suit.Button("Settings", {id="pause_settings"}, centerX, btnY, buttonWidth, buttonHeight)
    btnY = btnY + buttonHeight + 30
    -- Restart button (same as play again)
    local restartBtn = suit.Button("Restart", {id="pause_restart"}, centerX, btnY, buttonWidth, buttonHeight)
    if restartBtn.hit then
        resetGame()
        currentGameState = GameState.START_SELECT
    end
    btnY = btnY + buttonHeight + 30
    -- Main Menu button
    local menuBtn = suit.Button("Main Menu", {id="pause_menu"}, centerX, btnY, buttonWidth, buttonHeight)
    if menuBtn.hit then
        local goldEarned = math.floor(mapRangeClamped(math.sqrt(Player.score), 0, 100, 1.5, 6) * math.sqrt(Player.score))
        Player.addGold(goldEarned)
        saveGameData()
        resetGame()
        currentGameState = GameState.MENU
    end
    btnY = btnY + buttonHeight + 30
    -- Exit Game button
    local exitBtn = suit.Button("Exit Game", {id="pause_exit"}, centerX, btnY, buttonWidth, buttonHeight)
    if exitBtn.hit then
        local goldEarned = math.floor(mapRangeClamped(math.sqrt(Player.score), 0, 100, 1.5, 6) * math.sqrt(Player.score))
        Player.addGold(goldEarned)
        saveGameData()
        love.event.quit()
    end
end

function drawVictoryScreen()
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2
    setFont(64)
    love.graphics.setColor(1, 1, 0.5, 1)
    love.graphics.printf("VICTORY!", 0, centerY - 200, screenWidth, "center")
    setFont(36)
    love.graphics.setColor(0.4, 0.7, 1.0, 1) -- Light blue for Score
    love.graphics.printf("Score : " .. tostring(Player.score), 0, centerY - 80, screenWidth, "center")
    love.graphics.setColor(1.0, 0.85, 0.4, 1) -- Light gold for Gold
    love.graphics.printf("Gold earned : " .. tostring(Player.gold), 0, centerY - 30, screenWidth, "center")
    love.graphics.setColor(1, 1, 1, 1) -- White for Time
    love.graphics.printf("Time : " .. string.format("%02d:%02d", math.floor(gameTime / 60), math.floor(gameTime % 60)), 0, centerY + 20, screenWidth, "center")
    love.graphics.setColor(1.0, 0.6, 0.2, 1) -- Light orange for Bricks Destroyed
    love.graphics.printf("Bricks Destroyed : " .. tostring(Player.bricksDestroyed), 0, centerY + 70, screenWidth, "center")
    setFont(28)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    love.graphics.printf("Press R to restart or ESC to quit", 0, centerY + 2000, screenWidth, "center")

    -- Draw Main Menu and Upgrades buttons at the bottom using SUIT
    local buttonW, buttonH = 350, 125
    local spacing = 80
    local totalWidth = buttonW * 2 + spacing
    local startX = (screenWidth - totalWidth) / 2 
    local y = screenHeight * 3/4
    setFont(36)

    -- Main Menu button
    if suit.Button("Main Menu", {id = "victory_menu"}, startX, y, buttonW, buttonH).hit then
        resetGame()
        currentGameState = GameState.MENU
    end
    -- Upgrades button
    if suit.Button("Upgrades", {id = "victory_upgrades"}, startX + buttonW + spacing, y, buttonW, buttonH).hit then
        resetGame()
        currentGameState = GameState.UPGRADES
        loadGameData()
    end

    -- Draw SUIT UI elements (buttons)
    suit.draw()

    -- Draw buttons at the bottom of the screen
    local buttonY = screenHeight - 180
    local buttonW = 350
    local buttonH = 70
    local spacing = 60
    local totalWidth = buttonW * 2 + spacing
    local startX = (screenWidth - totalWidth) / 2
end

local old_love_draw = love.draw
function love.draw()
    love.graphics.setShader(backgroundShader)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setShader()

    resetButtonLastID()
    love.graphics.setColor(1, 1, 1, 1)
    if currentGameState == GameState.PAUSED then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setColor(1, 1, 1, 1)
        drawPauseMenu()
        suit.draw()
        return
    end

    if currentGameState == GameState.MENU then
        
        -- Draw menu
        drawMenu()
        -- Draw SUIT UI elements
        suit.draw()
        return
    end

    if currentGameState == GameState.START_SELECT then
        drawStartSelect()
        suit.draw()
        return
    end

    if currentGameState == GameState.UPGRADES then
        loadGameData() -- Load game data

        -- Draw SUIT UI elements
        suit.draw()
        -- Draw permanent upgrades
        permanentUpgrades.draw()
        return
    end

    if currentGameState == GameState.VICTORY then
        drawVictoryScreen()
        return
    end

    -- reset keyword system tooltip each frame
    KeywordSystem:resetTooltip()

    -- First render the game to the game canvas
    love.graphics.setCanvas(gameCanvas) -- Set the canvas for drawing
    love.graphics.clear()
    love.graphics.push()

    love.graphics.translate(screenOffset.x, screenOffset.y) -- Apply screen shake

    -- Draw game objects to glow canvases (at lower resolution)
    love.graphics.setCanvas(glowCanvas.bright)
    --love.graphics.clear()
    love.graphics.push()
    love.graphics.scale(0.5, 0.5) -- Downscale drawing for half-res canvas
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setCanvas(glowCanvas.bright)
    love.graphics.clear()
    -- Draw the paddle
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height)
    love.graphics.pop()

    love.graphics.push()
    love.graphics.scale(0.5, 0.5)
    if currentGameState == GameState.PLAYING then
        drawBricks() -- Draw bricks
    end
    love.graphics.pop()

    love.graphics.setCanvas(glowCanvas.bright)
    love.graphics.push()
    love.graphics.scale(0.5, 0.5)
    love.graphics.setColor(1, 1, 1, 1)
    Balls:draw() -- Draw balls
    love.graphics.pop()
    love.graphics.setCanvas()

    -- Apply glow effect and draw to main canvas
    love.graphics.setColor(1,1,1,1)
    love.graphics.setCanvas(gameCanvas)
    love.graphics.setShader(glowShader)

    -- draw bright canvas for glow effect
    glowShader:send("resolution", {screenWidth, screenHeight})
    glowShader:send("intensity", 1.25)
    love.graphics.draw(glowCanvas.bright, 0, 0, 0, 2, 2)
    love.graphics.setBlendMode("alpha")
    love.graphics.setShader()
    
    -- Now draw the paddle and other objects solid
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height)
    drawBricks()
    Balls.draw(Balls)

    love.graphics.setColor(1, 1, 1, 1)
    for i=1, Player.lives do
        love.graphics.draw(heartImg, -20, 75 + ((heartImg:getHeight()*2 + 5)*(i-1)), 0, 4, 4)
    end
    love.graphics.setCanvas(gameCanvas)
    --love.graphics.draw(glowCanvas.bright)

    -- Draw explosions
    Explosion.draw()

    drawDamageNumbers() -- Draw damage numbers

    drawAnimations() -- Draw animations

    drawMuzzleFlashes() -- Draw muzzle flashes
    
    love.graphics.pop()
    
    -- Draw the game timer
    drawGameTimer()

    upgradesUI.draw()

    -- Draw the UI elements using Suit
    suit.draw()
    dress:draw()    -- Draw tooltip last (on top of everything)
    KeywordSystem:drawTooltip()

    love.graphics.setCanvas(gameCanvas)
    VFX.draw() -- Draw VFX
    love.graphics.setCanvas()

    -- Draw the game canvas gameCanvasfirst
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gameCanvas)

    -- Draw damage numbers and other overlays AFTER drawing the game canvas
    drawDamageNumbers()
    drawAnimations()
    drawMuzzleFlashes()
    
    -- Then draw the shader overlay on top with some transparency to blend with the game
    love.graphics.setColor(1, 1, 1, 1.0) -- Adjust alpha for desired effect
    --love.graphics.draw(shaderOverlayCanvas)

    -- draw ui canvas
    love.graphics.draw(uiCanvas)

    if Player.dead then
        GameOverDraw()
    end
    drawFPS()

    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    setFont(20)
end

local old_love_keypressed = love.keypressed
function love.keypressed(key)
    if key == "escape" then
        if currentGameState == GameState.PLAYING then
            currentGameState = GameState.PAUSED
            return
        elseif currentGameState == GameState.PAUSED then
            currentGameState = GameState.PLAYING
            return
        else
            love.event.quit()
            return
        end
    end

    -- Reset game when R is pressed
    if key == "r" then
        dmgVFXOn = not dmgVFXOn
    end

    if key == "c" then
        Player.die()
    end

    -- freeze
    if key == "f" then
        toggleFreeze()
    end

    if key == "b" then
        Player.level = Player.level + 1
        setLevelUpShop(false, true)
        Player.levelingUp = true -- This will trigger the upgrade UI
    end

    --money manipulation
    if key == "m" then
        Player.money = Player.money < 10 and 10 or Player.money * 10
    end
    if key == "n" then
        Player.money = 0
    end

    --time manipulation
    if key == "l" then
        playRate = playRate * 2
    end
    if key == "k" then 
        playRate = 1
    end
    if key == "j" then 
        playRate = playRate / 2
    end
    -- flip la valeur de draw debug
    if key == "g" then
        VFX.flipDrawDebug()
    end

    --test damage screen visuals 
    if key == "v" then
        currentGameState = GameState.VICTORY
    end
    if key == "b" then
        damageThisFrame = boopah
    end

    --test ball hit vfx
    if key == "y" then
        for _,ball in ipairs(Balls) do
            ballHitVFX(ball)
        end
    end

    if key == "q" then
        print("highscore : " .. Player.highScore)
        print("Player.gold : " .. Player.gold)
        print("Player.startingMoney : " .. Player.startingMoney)
        print("#permanentUpgrades : " .. #Player.permanentUpgrades)
    end


    --print brick speed mult calculation
    if key == "t" then
        spawnBoss()
    end

    if key == "=" then
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            for _, brick in ipairs(bricks) do
                if not brick.destroyed then
                    brick.health = brick.health + 1
                    brick.color = getBrickColor(brick.health)
                end
            end
        else end
    end 
    if key == "-" then
        for _, brick in ipairs(bricks) do
            if not brick.destroyed then
                brick.health = brick.health - 1
                brick.color = getBrickColor(brick.health)
            end
        end
    end

    if key == "i" then
        Balls.addBall("Machine Gun")
    end
end

function love.mousepressed(x, y, button)
    if button == 2 then
        -- Handle UI upgrade click
        if currentlyHoveredButton then
            upgradesUI.queueUpgrade(currentlyHoveredButton)
        end
    end
end


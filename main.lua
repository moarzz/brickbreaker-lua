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

-- Game states
GameState = {
    MENU = "menu",
    START_SELECT = "start_select",
    PLAYING = "playing",
    SETTINGS = "settings",
    UPGRADES = "upgrades",
    TUTORIAL = "tutorial"
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
        x = screenWidth / 2 - 50,
        y = screenHeight - 400,
        width = 150,
        widthMult = 1,
        height = 20,
        speed = 400,
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
end

local function loadAssets()
    --load images
    auraImg = love.graphics.newImage("assets/sprites/aura.png")
    brickImg = love.graphics.newImage("assets/sprites/brick.png")
    muzzleFlashImg = love.graphics.newImage("assets/sprites/muzzleFlash.png")
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

    Player.loadJsonValues()
end

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

local unavailableXpos = {}
local currentRow = 1
local nextRowDebuff = 0
local function generateRow(brickCount, yPos)
    brickCount = brickCount - nextRowDebuff
    nextRowDebuff = 0 -- Reset next row debuff for the next row
    if brickCount >= 1000 then
        print("SPAWN BOSS MOUAHAHAHAHAA")
    end
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
                        local brickColor = getBrickColor(bigBrickHealth)
                        nextRowDebuff = brickHealth + row[xPos+1] -- Set the next row debuff to the health of the big brick
                        table.insert(bricks, {
                            type = "big",
                            id = #bricks + 1,
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
                            color = {brickColor[1], brickColor[2], brickColor[3], 1}, -- Set the color with full opacity
                            hitLastFrame = false
                        })
                        nextRowDebuff = brickHealth + row[xPos+1]
                    end
                else
                    local brickColor = getBrickColor(brickHealth)
                    table.insert(bricks, {
                        type = "small",
                        id = #bricks + 1,
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
                        color = {brickColor[1], brickColor[2], brickColor[3], 1}, -- Set the color with full opacity
                        hitLastFrame = false
                    })
                end
            end
        end
    end
    currentRow = currentRow + 1
    return row
end

local currentRowPopulation
local function addMoreBricks()
    if bricks[#bricks] then
        if bricks[#bricks].y > -50 then
            print("spawning more bricks")
            for i=1 , 10 do
                generateRow(currentRowPopulation, i * -(brickHeight + brickSpacing) - 50) --generate 100 scaling rows of bricks
                currentRowPopulation = currentRowPopulation + 1 + math.floor(currentRow/20)
            end
            return
        else 
            return
        end--else print("bricks are too high to spawn more") end
    end
end

function getBrickColor(health)
    -- Full circle of hue rotation (360 degrees) reached at health 100
    -- Starting at yellow (60) and going counter-clockwise
    
    -- Use a square root function to slow down the color change at higher health values
    local scaledHealth = math.sqrt(health / 200) * 200
    local hue = 100 - (scaledHealth - 1) * (360/100)
    
    -- Wrap hue to keep it in 0-360 range
    if hue < 0 then hue = hue + 360 end
    
    -- Saturation decreases more slowly, using square root scaling
    local saturation = math.max(0, 1 - math.sqrt((health - 1) / 100))
    
    -- Lightness stays constant
    local lightness = 0.5
    
    -- Alpha is always 1
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
    brickFont = love.graphics.newFont(14)    -- Set fullscreen mode
    love.window.setMode(1920, 1080, {fullscreen = true, vsync = false})    -- Get screen dimensions
    screenWidth, screenHeight = love.graphics.getDimensions()
    gameCanvas = love.graphics.newCanvas(screenWidth, screenHeight)
    uiCanvas = love.graphics.newCanvas(screenWidth, screenHeight)
    -- Create glow canvas with HDR and proper alpha support
    glowCanvas = {
        weak = love.graphics.newCanvas(screenWidth, screenHeight, {
            format = "rgba16f",
            msaa = 4
        }),
        normal = love.graphics.newCanvas(screenWidth, screenHeight, {
            format = "rgba16f",
            msaa = 4
        }),
        bright = love.graphics.newCanvas(screenWidth, screenHeight, {
            format = "rgba16f",
            msaa = 4
        })
    }
    
    -- Create a new canvas for the shader overlay
    shaderOverlayCanvas = love.graphics.newCanvas(screenWidth, screenHeight)

    love.window.setTitle("Brick Breaker")    -- Reset game start time and frozen time tracking

    -- Paddle
    paddle = {
        x = screenWidth / 2 - 50,
        y = screenHeight/4,
        width = 130,
        widthMult = 1,
        height = 20,    
        speed = 400,
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
    return timeSinceStart < 600 and mapRangeClamped(timeSinceStart, 0, 600, 0.35, 1.0) or mapRange(timeSinceStart, 600, 2000, 1.0, 5.0)
end

local function getBrickSpeedMult() 
    -- Get the position-based multiplier
    local posMult = 1
    for i, brick in ipairs(bricks) do
        if not brick.destroyed then
            posMult = mapRangeClamped(brick.y, 0, (paddle.y/2 - brickHeight), 10, 1)
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
                brick.y = brick.y - 300 * dt
            end
        end
    else
        -- Normal speed calculation
        local speedMult = getBrickSpeedMult() -- Get the combined speed multiplier
        for _, brick in ipairs(bricks) do
            if not brick.destroyed then
                brick.y = brick.y + brickSpeed.value * dt * speedMult
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
                brickpiece = nil
            end
        end
    end
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

    if currentGameState == GameState.PLAYING then
        KeywordSystem:update() -- Update the keyword system
        -- overwrites backgroundIntensity if using debugging window
        if shouldDrawDebug then
            backgroundIntensity = VFX.backgroundIntensityOverwrite 
        end

        brickPiecesUpdate(dt) -- Update brick pieces
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
            --if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
                moveY = moveY - 0.2
            --end
            --[[if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
                moveY = moveY + 1
            end

            -- Normalize diagonal movement
            if moveX ~= 0 and moveY ~= 0 then
                moveX = moveX * 0.7071
                moveY = moveY * 0.7071
            end]]

            paddle.x = paddle.x + moveX * paddle.speed * paddle.speedMult * dt
            paddle.y = paddle.y + moveY * paddle.speed * paddle.speedMult * dt

            -- Optionally update currentSpeedX/currentSpeedY for other logic
            paddle.currentSpeedX = moveX * paddle.speed * paddle.speedMult
            paddle.currentSpeedY = moveY * paddle.speed * paddle.speedMult

            -- Keep paddle within screen bounds
            paddle.x = math.max(statsWidth, math.min(screenWidth - statsWidth - paddle.width, paddle.x))
            paddle.y = math.max(math.max(getHighestBrickY() + brickHeight*6, 5*screenHeight/16), math.min(screenHeight - paddle.height - 10, paddle.y))

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
                playSoundEffect(brickDeathSFX, 0.35, 1, false, true)
            end
            if damageThisFrame > 0 and damageCooldown <= 0 then
                damageScreenVisuals(mapRangeClamped(damageThisFrame,1,20,0.25, 0.5), damageThisFrame)
                playSoundEffect(brickHitSFX, mapRangeClamped(damageThisFrame, 1,10, 0.4,1.0), mapRangeClamped(damageThisFrame,1,20,0.5,1), false, true)
                damageCooldown = 0.025 -- Set cooldown for damage visuals
            end
            brickKilledThisFrame = false -- Reset brick hit state for the next frame
            damageThisFrame = 0 -- Reset damage this frame
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

-- Add a new function for the starting item selection screen
local function drawStartSelect()
    local centerX = screenWidth / 2 - buttonWidth / 2
    local startY = screenHeight / 3
    setFont(36)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Choose your starting item", screenWidth / 2 - getTextSize("Choose your starting item") / 2, startY - 100)

    -- Define the canonical order
    local canonicalOrder = {"Ball", "Pistol", "Laser Beam", "Saw Blades", "Nothing"}
    local displayNames = {
        ["Ball"] = "Ball",
        ["Pistol"] = "Pistol",
        ["Laser Beam"] = "Laser Beam",
        ["Saw Blades"] = "Saw Blades",
        ["Nothing"] = "Nothing"
    }

    -- Build the startingItems list in canonical order, only if unlocked
    local startingItems = {}
    for _, name in ipairs(canonicalOrder) do
        if name == "Ball" or (Player.unlockedStartingBalls and Player.unlockedStartingBalls[name]) then
            table.insert(startingItems, {name = name, id = "start_"..name:gsub(" ", "_"), label = displayNames[name]})
        elseif name == "Nothing" then
            -- Always include Nothing if unlocked or in startingItems
            if Player.unlockedStartingBalls and Player.unlockedStartingBalls["Nothing"] then
                table.insert(startingItems, {name = name, id = "start_"..name:gsub(" ", "_"), label = displayNames[name]})
            end
        end
    end
    table.insert(startingItems, {name = "Nothing", id = "start_Nothing", label = "Nothing"}) -- Always include Nothing at the top

    -- Draw buttons for each starting item
    local btnY = startY
    for i, item in ipairs(startingItems) do
        local btn = suit.Button(item.label, {id = item.id}, centerX, btnY, buttonWidth, buttonHeight)
        if btn.hit then
            startingChoice = item.name
            currentGameState = GameState.PLAYING
            initializeGameState()
            if item.name ~= "Nothing" then
                Balls.addBall(item.name)
            end
        end
        btnY = btnY + buttonHeight + 40
    end
end

function drawBricks()
    for _, brick in ipairs(bricks) do
        if not brick.destroyed and brick.y > 0 - brick.height - 5 then
            -- Ensure brick color is valid
            local color = brick.color or {1, 1, 1, 1}
            love.graphics.setColor(color) -- Set brick color

            -- Use drawScale for scaling, default to 1 if not set
            local scale = brick.drawScale or 1
            local scaleX = scale * (brick.width / brickImg:getWidth())
            local scaleY = scale * (brick.height / brickImg:getHeight())

            -- Centered scaling: adjust position so scaling keeps brick centered
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

            -- Draw the brick's HP using drawTextWithOutline, centered in the scaled brick
            local textColor = {1, 1, 1, 1} -- White text color
            local outlineColor = {0, 0, 0, 1} -- Black outline color
            local outlineThickness = 1
            local hpText = tostring(brick.health or 0)

            setFont(18)
            drawTextWithOutline(
                hpText,
                centerX,
                centerY,
                love.graphics.getFont(),
                textColor,
                outlineColor,
                outlineThickness
            )
        end
    end
    for _, brickPiece in ipairs(brickPieces) do
        love.graphics.setColor(brickPiece.color) -- Reset color to white
        love.graphics.draw(brickPiece.img, brickPiece.x, brickPiece.y, 0, brickPiece.width / brickPiece.img:getWidth(), brickPiece.height / brickPiece.img:getHeight())
    end
end

local frozenTime = 0
local lastFreezeTime = 0


local function drawGameTimer()
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    local timeString = string.format("%02d:%02d", minutes, seconds)
    
    -- Draw timer
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(timeString)
    local x = screenWidth / 2 - textWidth / 2
    local y = 20
    
    love.graphics.setColor(1, 1, 1, 1)
    setFont(50)
    love.graphics.print(timeString, x, y)
    if playRate ~= 1 then
        setFont(24)
        love.graphics.print(string.format(playRate) .. "X", x + textWidth + 10, y + 50)
    end
end

function love.draw()
    resetButtonLastID()
    love.graphics.setColor(1, 1, 1, 1)

    if currentGameState == GameState.MENU then
        -- Draw background
        love.graphics.setShader(backgroundShader)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setShader()
        
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
        -- Draw background
        love.graphics.setShader(backgroundShader)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setShader()

        -- Draw SUIT UI elements
        suit.draw()
        -- Draw permanent upgrades
        permanentUpgrades.draw()
        return
    end

    -- reset keyword system tooltip each frame
    KeywordSystem:resetTooltip()

    -- First render the game to the game canvas
    love.graphics.setCanvas(gameCanvas) -- Set the canvas for drawing
    love.graphics.clear()
    love.graphics.push()

    love.graphics.setShader(backgroundShader)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setShader()    love.graphics.translate(screenOffset.x, screenOffset.y) -- Apply screen shake    -- Draw game objects to glow canvas first
    love.graphics.setCanvas(glowCanvas.normal)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1, 1)
    -- Draw the paddle
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height)

    love.graphics.setCanvas(glowCanvas.bright)
    love.graphics.clear()
    drawBricks() -- Draw bricks

    love.graphics.setCanvas(glowCanvas.normal)
    Balls:draw() -- Draw balls

    love.graphics.setCanvas()

    -- Apply glow effect and draw to main canvas
    love.graphics.setColor(1,1,1,1)
    love.graphics.setCanvas(gameCanvas)
    love.graphics.setShader(glowShader)
    glowShader:send("resolution", {screenWidth, screenHeight})
    glowShader:send("intensity", 1.0)
    love.graphics.setBlendMode("add") -- Simple additive blending
    love.graphics.draw(glowCanvas.normal)

    -- draw bright canvas for glow effect
    glowShader:send("intensity", 1.5)
    love.graphics.draw(glowCanvas.bright)

    love.graphics.setBlendMode("alpha") -- Reset blend mode
    love.graphics.setShader()
    
    -- Draw everything else normally
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height)
    drawBricks() -- Draw bricks again for solid appearance
    Balls.draw(Balls) -- Draw balls again for solid appearance

    -- Draw explosions
    Explosion.draw()

    drawDamageNumbers() -- Draw damage numbers

    drawAnimations() -- Draw animations

    drawMuzzleFlashes() -- Draw muzzle flashes
    
    love.graphics.pop()
    
    upgradesUI.draw()

    -- Draw the UI elements using Suit
    suit.draw()
    dress:draw()    -- Draw tooltip last (on top of everything)
    KeywordSystem:drawTooltip()

    -- Draw the game timer
    drawGameTimer()

    love.graphics.setCanvas(gameCanvas)
    VFX.draw() -- Draw VFX
    love.graphics.setCanvas()

    -- Draw the game canvas gameCanvasfirst
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gameCanvas)
    
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
end

local boopah = 1
boopag = 1
--exit game with esc key and other debugging keys
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end    -- Reset game when R is pressed
    if key == "r" then
        resetGame()
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
        setLevelUpShop(true, true)
        Player.levelingUp = true -- This will trigger the upgrade UI
        --damageNumber(4,screenWidth/2,screenHeight/2,{1,1,1,1})
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

    -- reset
    if key == "r" then
        love.event.quit("restart")
    end

    -- flip la valeur de draw debug
    if key == "g" then
        VFX.flipDrawDebug()
    end

    --test damage screen visuals 
    if key == "v" then
        boopah = boopah + 2
        boopag = boopag + 2
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

    if key == "7" then
        Player.gold = 0
        saveGameData()
    end
    if key == "8" then 
        Player.gold = Player.gold + 1000
        saveGameData()
    end


    --print brick speed mult calculation
    if key == "t" then
        local total = 0
        for _, ball in ipairs(Balls) do
            if ball.name == "Exploding Ball" and ball.dead == false then
                total = total + 1
            end
        end
        print("total fireballs alive: " .. total)
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


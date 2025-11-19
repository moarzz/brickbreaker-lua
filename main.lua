LoveAffix = require("Libraries.loveAffix").init();
SimpleShader = require("Libraries.simpleShader").init();
WindowCorrector = require("Libraries.windowCorrector");

--! these three *need* to be the first code 2 run otherwise i will eat you

EventQueueRef = require("Libraries.eventQueue.eventQueue")
Events = require("Libraries.eventQueue.events")

require("limitFPS"); -- limit the fps

Textures = require("textures") -- for CROOKYYYYY
Crooky = require("crooky") -- tax evasion goat

UtilityFunction = require("UtilityFunction") -- utility functions
Player = require("Player") -- player logic
Balls = require("Balls") -- ball logic
FancyText = require("Libraries.fancyText") -- fancy text rendering
upgradesUI = require("upgradesUI") -- upgrade UI logic
Timer = require("Libraries.timer") -- timer library
GlobalTimer = Timer.new() -- Timer that runs even when paused
local permanentUpgrades = require("permanentUpgrades") -- permanent upgrades UI
local damageRipples = require("DamageRipples") -- damage ripple shader
confetti = require("particleSystems.confetti") -- confetti particle system
shaders = require("shaders") -- shader logic
suit = require("Libraries.Suit") -- UI library
tween = require("Libraries.tween") -- tweening library
VFX = require("VFX") -- VFX library
local KeywordSystem = require("KeywordSystem") -- Keyword system for text parsing
local Explosion = require("particleSystems.explosion") -- Explosion particle system
BackgroundShader = require("backgroundShader");
TextBatching = require("textBatching");

usingMoneySystem = false
usingNormalXpSystem = true
goldEarnedFrl = 0 -- ignore, mais delete pas
local startingItemName = nil

-- Cache for brick HP text objects
local brickTextCache = {
    objects = {},  -- Cache Text objects
    widths = {},   -- Cache text widths
    font = nil     -- Store font reference
}

-- Game states
GameState = {
    MENU = "menu",
    START_SELECT = "start_select",
    PLAYING = "playing",
    PAUSED = "paused",
    SETTINGS = "settings",
    UPGRADES = "Shop",
    TUTORIAL = "tutorial",
    VICTORY = "victory",
    GAMEOVER = "gameover",
}
currentGameState = GameState.MENU
love.mouse.setVisible(true)

-- Add settings variables
musicVolume = 1
sfxVolume = 1
fullScreenCheckbox = love.window.getFullscreen()

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
gameTime = 0  -- Tracks actual elapsed gameplay time
bossSpawned = false
local spawnBossNextRow = false
healThisFrame = 0

local mt = {
    __index = function(t, k)
        local value = rawget(t, k)
        if hasItem("Huge Paddle") and k == "width" then
            if hasItem("Four Leafed Clover") then
                return value * 2.25
            else
                return value * 1.5
            end
        else
            return value
        end
    end
}

function resetGame()
    for i = #Tweens, 1, -1 do
        removeTween(Tweens[i].id)
    end
    
    resetLocalUtilityTable()

    -- Utility function values reset
    resetTextPopups()

    -- Clear event queue
    if EventQueue and EventQueue.clear then
        EventQueue:clear()
    end
    
    -- Reset visual states
    visualMoneyValues = {scale = 1}
    visualItemValues = {}
    visualUpgradePriceValues = {}
    visualStatValues = {}
    
    -- Stop any confetti effect
    stopConfetti()
    Timer.clear()
    if EventQueue and EventQueue.clear then EventQueue:clear() end
    if fancyTexts then
        for k,_ in pairs(fancyTexts) do fancyTexts[k] = nil end
    end
    
    -- Clear text cache
    for _, text in pairs(brickTextCache.objects) do
        text:release()
    end
    brickTextCache.objects = {}
    brickTextCache.widths = {}
    brickTextCache.font = nil
    
    -- Reset game state
    currentGameState = GameState.MENU
    love.mouse.setVisible(true)
    
    -- Reset game timers
    gameStartTime = love.timer.getTime()
    gameTime = 0
    frozenTime = 0
    lastFreezeTime = 0
    
    -- Reset gameplay variables
    playRate = 1
    backgroundIntensity = 0
    spawnTimer = 0
    bossSpawned = false
    spawnBossNextRow = false
    currentSpawnRate = 1.0
    currentRowPopulation = 1
    damageThisFrame = 0
    
    -- Reset screen effects
    screenOffset = {x = 0, y = 0}
    
    -- Reset paddle to default position and size
    paddle = {
        x = screenWidth / 2 - 100,
        y = screenHeight - 400,
        _width = 300, -- Base width + size upgrade
        widthMult = 1,
        height = 20,
        speed = 700,
        currrentSpeedX = 0,
        speedMult = 1
    }
    setmetatable(paddle, {
        __index = function(t, k)
            if k == "width" then
                local value = rawget(t, "_width")
                if hasItem("Huge Paddle") then
                    return value * 1.75
                else
                    return value
                end
            else
                return rawget(t, k)
            end
        end,
        __newindex = function(t, k, v)
            if k == "width" then
                v = hasItem("Huge Paddle") and v / 1.75 or v
                rawset(t, "_width", v)
            else
                rawset(t, k, v)
            end
        end
    })
    
    -- Clear any existing bricks
    bricks = {}
    shieldAuras = {}
    brickBatch = love.graphics.newSpriteBatch(brickImg, 700, "stream");
    
    -- Reset all Player stats and values
    Player.reset()
    
    -- Reset balls
    for i = #Balls, 1, -1 do
        Balls[i] = nil
    end
    Balls.clearUnlockedBallTypes()
    Balls.initialize()
    Player.initialize()

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
    resetLvlUpPopups()
end

local function loadAssets()

    EventQueue = EventQueueRef.new()
    --load images
    pixelTexture = love.graphics.newImage("assets/sprites/pixel.png");
    paddleImg = love.graphics.newImage("assets/sprites/paddle.png")
    auraImg = love.graphics.newImage("assets/sprites/aura.png")
    healImg = love.graphics.newImage("assets/sprites/heal.png")
    brickImg = love.graphics.newImage("assets/sprites/brick.png")
    goldBrickImg = love.graphics.newImage("assets/sprites/goldBrick.png")
    bossBrickImg = love.graphics.newImage("assets/sprites/bossBrick.png")
    crownImg = love.graphics.newImage("assets/sprites/crown.png")
    heartImg = love.graphics.newImage("assets/sprites/heart.png")
    muzzleFlashImg = love.graphics.newImage("assets/sprites/muzzleFlash.png")
    turretImg = love.graphics.newImage("assets/sprites/turret.png")
    turretBaseImg = love.graphics.newImage("assets/sprites/turretBase.png")
    turretGunImg = love.graphics.newImage("assets/sprites/turretGun.png")
    brickPiece1Img = love.graphics.newImage("assets/sprites/brickPiece1.png")
    brickPiece2Img = love.graphics.newImage("assets/sprites/brickPiece2.png")
    brickPiece3Img = love.graphics.newImage("assets/sprites/brickPiece3.png")
    vignetteImg = love.graphics.newImage("assets/sprites/vignette.png")
    drillSergeantImg = love.graphics.newImage("assets/sprites/drillSergeant.png")
    healAuraImg = love.graphics.newImage("assets/sprites/healAura.png")
    shieldAuraImg = love.graphics.newImage("assets/sprites/shieldAura.png")
    defaultItemImage = love.graphics.newImage("assets/sprites/UI/ItemIcons/default.png")
    defaultScreenImg = love.graphics.newImage("assets/sprites/firstUpgradeShop/defaultScreen.png")
    tutorialScreen1Img = love.graphics.newImage("assets/sprites/firstUpgradeShop/screen1.png")
    tutorialScreen2Img = love.graphics.newImage("assets/sprites/firstUpgradeShop/screen2.png")
    tutorialScreen3Img = love.graphics.newImage("assets/sprites/firstUpgradeShop/screen3.png")
    tutorialScreen4Img = love.graphics.newImage("assets/sprites/firstUpgradeShop/screen4.png")
    lightBeamImg = love.graphics.newImage("assets/sprites/lightBeam.png")
    bossBrickOverlayImg = love.graphics.newImage("assets/sprites/bossBrickOverlay.png")

    -- UI
    uiLabelImg = love.graphics.newImage("assets/sprites/UI/label.png")
    uiSmallWindowImg = love.graphics.newImage("assets/sprites/UI/windowSmall.png")
    uiWindowImg = love.graphics.newImage("assets/sprites/UI/window.png")
    uiBigWindowImg = love.graphics.newImage("assets/sprites/UI/windowTall.png")
    leftArrowImg = love.graphics.newImage("assets/sprites/UI/leftArrow.png")
    rightArrowImg = love.graphics.newImage("assets/sprites/UI/rightArrow.png")
    titleImg = love.graphics.newImage("assets/sprites/BreakLoop_Title.png")
    --Icons
    iconsImg = {
        amount = love.graphics.newImage("assets/sprites/UI/icons/New/amount.png"),
        ammo = love.graphics.newImage("assets/sprites/UI/icons/New/ammo.png"),
        damage = love.graphics.newImage("assets/sprites/UI/icons/New/damage.png"),
        cooldown = love.graphics.newImage("assets/sprites/UI/icons/New/cooldown.png"),
        fireRate = love.graphics.newImage("assets/sprites/UI/icons/New/fireRate.png"),
        speed = love.graphics.newImage("assets/sprites/UI/icons/New/speed.png"),
        range = love.graphics.newImage("assets/sprites/UI/icons/New/range.png"),
    }
    --powerups
    powerupImgs = {
        moneyBag = love.graphics.newImage("assets/sprites/powerups/moneyBag.png"),
        freeze = love.graphics.newImage("assets/sprites/powerups/freeze.png"),
        nuke = love.graphics.newImage("assets/sprites/powerups/nuke.png"),
        doubleDamage = love.graphics.newImage("assets/sprites/powerups/doubleDamage.png"),
        acceleration = love.graphics.newImage("assets/sprites/powerups/acceleration.png"),
        dollarBill = love.graphics.newImage("assets/sprites/dollarBill.png"),
    }

    -- load sounds
    brickHitSFX = love.audio.newSource("assets/SFX/brickBoop.mp3", "static")
    healSFX = love.audio.newSource("assets/SFX/heal.mp3", "static")
    paddleBoopSFX = love.audio.newSource("assets/SFX/paddleBoop.mp3", "static")
    wallBoopSFX = love.audio.newSource("assets/SFX/wallBoop.mp3", "static")
    explosionSFX = love.audio.newSource("assets/SFX/explosion.mp3", "static") -- Add explosion sound if available
    brickDeathSFX = love.audio.newSource("assets/SFX/brickDeath.mp3", "static")
    gunShootSFX = love.audio.newSource("assets/SFX/gunShoot.mp3", "static") -- Add gun shoot sound if available
    lvlUpSFX = love.audio.newSource("assets/SFX/lvlUp.mp3", "static")
    upgradeSFX = love.audio.newSource("assets/SFX/upgrade.mp3", "static")
    loseMoneySFX = love.audio.newSource("assets/SFX/loseMoney.mp3", "static")
    selectSFX = love.audio.newSource("assets/SFX/select.mp3", "static")
    laserSFX = love.audio.newSource("assets/SFX/laser.mp3", "static")
    lightningPulseSFX = love.audio.newSource("assets/SFX/lightningPulse.mp3", "static")
    lightningSFX = love.audio.newSource("assets/SFX/lightning.mp3", "static")
    lightBeamSFX = love.audio.newSource("assets/SFX/lightBeam.mp3", "static")
    gainXpSFX = love.audio.newSource("assets/SFX/gainXp.mp3", "static")
    shieldBlockSFX = love.audio.newSource("assets/SFX/shieldBlock.mp3", "static")


    -- load shaders
    -- backgroundShader = love.graphics.newShader("background", "Shaders/background.glsl")
    glowShader = love.graphics.newShader("glow", "Shaders/glow.glsl")

    -- load spriteSheets
    impactVFX = love.graphics.newImage("assets/sprites/VFX/Impact.png")
    smokeVFX = love.graphics.newImage("assets/sprites/VFX/smoke.png")
    sparkVFX = love.graphics.newImage("assets/sprites/VFX/spark.png")
    lightningVFX = love.graphics.newImage("assets/sprites/VFX/spark.png")
    chainLightningVFX = love.graphics.newImage("assets/sprites/VFX/chainLightning.png")
    explosionVFX = love.graphics.newImage("assets/sprites/VFX/explosion.png")
    fireballVFX = love.graphics.newImage("assets/sprites/VFX/fireball.png")
    sawBladesVFX = love.graphics.newImage("assets/sprites/VFX/sawBlades.png")
    rocketVFX = love.graphics.newImage("assets/sprites/VFX/rocket.png")
    fireVFX = love.graphics.newImage("assets/sprites/VFX/fire.png")
    sparkleVFX = love.graphics.newImage("assets/sprites/VFX/sparkle.png")
    slashVFX = love.graphics.newImage("assets/sprites/VFX/slash.png")

    Player.loadJsonValues()
    damageRipples.load()
    Crooky:load()
    
end

dmgVFXOn = true

local targetMusicVolume = 1

local canHeal = true
local bossWidth, bossHeight = 500, 300
local bossHealth = 10000
local brickId = 1
local bossBrickSpawnTimer
local bossSpawnSwitch = true
local boss = nil
local function spawnBoss()
    currentRowPopulation = 900
    targetMusicVolume = 0
    -- Center the boss brick at the top
    Timer.after(8, function()
        targetMusicVolume = 1
        changeMusic("boss")
    end)
    print("Spawning boss brick")
    local bossX = screenWidth / 2 - bossWidth / 2
    local bossY = -bossHeight * 2
    local brickColor = getBrickColor(bossHealth, false, true)
    boss = {
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
        hitLastFrame = false,
        lastHitVfxTime = 0,
    }
    table.insert(bricks, boss)
    brickId = brickId + 1
    --[[bossBrickSpawnTimer = Timer.every(1.25, function() 
        if boss.y >= -bossHeight + 150 then
            bossSpawnSwitch = not bossSpawnSwitch
            local bossPosY
            for _, brick in ipairs(bricks) do 
                if brick.type == "boss" then
                    bossPosY = brick.y
                end
            end
            local health = math.random(60,125)
            table.insert(bricks, 2, {
                type = "small",
                id = brickId,
                x = bossX + 10 + math.random(1, math.floor(bossWidth - brickWidth - 20))/2 + (bossWidth - brickWidth - 20)/2 * (bossSpawnSwitch and 1 or 0),
                y = (bossPosY or -100) + bossHeight - brickHeight*2 - 25,
                drawOffsetX = 0,
                drawOffsetY = 0,
                drawOffsetRot = 0,
                drawScale = 1,
                speedMult = 1.85,
                width = brickWidth,
                height = brickHeight,
                destroyed = false,
                health = health,
                maxHealth = health,
                color = {brickColor[1], brickColor[2], brickColor[3], 1},
                hitLastFrame = false,
                lastHitVfxTime = 0,
            })
            brickId = brickId + 1
        end
    end)]]
    local bossHealTimer = Timer.every(2, function()
        if boss.y >= -bossHeight + 150 and canHeal then

            --[[ self heal
            local healValue = math.floor(mapRange(boss.health, 1, 5000, 1, 50))
            boss.health = boss.health + healValue
            healThisFrame = healThisFrame + healValue
            healNumber(healValue, boss.x + boss.width/2, math.max(10, boss.y + boss.height/2))]]
            for _, brick in ipairs(bricks) do
                if brick.type ~= "boss" then
                    local healAmount = math.ceil(brick.health/(brick.type == "big" and 160 or 80))
                    brick.health = brick.health + healAmount
                    brick.color = getBrickColor(brick.health, brick.type == "big")
                    healNumber(healAmount, brick.x + brick.width/2, brick.y + brick.height/2)
                    healThisFrame = healThisFrame + healAmount
                end
            end
        end
    end)
end

local function victoryTheme()
    changeMusic("victory")
    GlobalTimer.after(25, function()
        targetMusicVolume = 0
    end)
end

local totalGoldBricksGeneratedThisRun = 0
function resetGoldBricksValues()
    totalGoldBricksGeneratedThisRun = 0
end

local fastBricks = {}
local lastFastBrickCreateTime = 0
function fastBricksReset()
    fastBricks = {}
    lastFastBrickCreateTime = 0
end
local function createFastBrick()
    local brickHealth = math.max(math.floor(currentRowPopulation/35), 1)
    local brickColor = getBrickColor(brickHealth)
    local fastBrick ={
        type = "fast",
        id = brickId,
        x = math.random(5, screenWidth - brickWidth - 5),
        y = -brickHeight,
        drawOffsetX = 0,
        drawOffsetY = 0,
        drawOffsetRot = 0,
        drawScale = 1,
        width = brickWidth,
        height = brickHeight,
        destroyed = false,
        health = brickHealth,
        maxHealth = brickHealth,
        color = {brickColor[1], brickColor[2], brickColor[3], 1},
        hitLastFrame = false,
        lastHitVfxTime = 0,
        trail = {},
        speedMult = 1,
    }
    function fastBrick:addTrailPoint(x,y)
        table.insert(self.trail, 1, {x = x, y = y})
        if #self.trail > 15 then
            table.remove(self.trail, #self.trail)
        end
    end
    table.insert(bricks,1, fastBrick)
    table.insert(fastBricks, fastBrick)
    lastFastBrickCreateTime = gameTime
    brickId = brickId + 1
end

local function createFastBrickUpdate()
    local fastBrickTimer = false
    if bossSpawned then 
        fastBrickTimer = gameTime - lastFastBrickCreateTime >= 2
    else
        fastBrickTimer = gameTime - lastFastBrickCreateTime >= mapRangeClamped(Player.level, 5, 20, 8, 2)
    end
    if Player.level >= 5 and fastBrickTimer then
        createFastBrick()
    end
end

local function fastBricksUpdate()
    for _, brick in ipairs(fastBricks) do
        if not brick.lastTrailUpdateTime then
            brick.lastTrailUpdateTime = gameTime
        end
        if gameTime - brick.lastTrailUpdateTime >= 0.075 then
            brick:addTrailPoint(brick.x, brick.y)
            brick.lastTrailUpdateTime = gameTime
        end
    end
end

local healBricks = {}
local unavailableXpos = {}
local blockedRows = {}
local currentRow = 1
local nextRowDebuff = 0
local function generateRow(brickCount, yPos)
    if victoryAchieved then
        return
    end
    local rowXOffset = math.random(-15,15)
    local startLocation = usingMoneySystem and statsWidth or 30
    local columnCount = usingMoneySystem and 12 or 22
    brickCount = brickCount - nextRowDebuff
    nextRowDebuff = 0 -- Reset next row debuff for the next row
    local row = usingMoneySystem and {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0} or {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    local rowOffset = 0--mapRangeClamped(math.random(0,10),0,10, 0, brickWidth)
    
    if bossSpawned and not bossDead then
        local num1, num2 = usingMoneySystem and 4 or 9, usingMoneySystem and 9 or 14
        for i = num1, num2 do
            blockedRows[i] = true
        end
    end

    if not bossSpawned then
        local blockedRowCount = math.random(0,13)
        if blockedRowCount ~= 0 then
            blockedRows = {}
            for i=1, blockedRowCount do
                local doAgain = true
                local iterations = 1
                while doAgain do
                    iterations = iterations + 1
                    local blockedRow = math.random(1,22)
                    if not blockedRows[blockedRow] then
                        blockedRows[blockedRow] = true
                        doAgain = false
                    end
                    if iterations >= 35 then
                        doAgain = false
                    end
                end
            end

        end
    end
    
    -- Pre-calculate available positions
    local availablePositions = {}
    for i = 1, columnCount do
        if not (unavailableXpos[i] or blockedRows[i]) then
            table.insert(availablePositions, i)
        end
    end
    
    -- If no available positions, return early
    if #availablePositions == 0 then
        unavailableXpos = {}
        currentRow = currentRow + 1
        return row
    end
    
    -- Distribute bricks using weighted random distribution
    local remaining = brickCount
    for i = 1, #availablePositions do
        local pos = availablePositions[i]
        local expectedShare = remaining / (#availablePositions - i + 1)
        
        -- Add some randomness while keeping it efficient
        local actualShare = math.max(0, math.floor(expectedShare + math.random(-expectedShare/4, expectedShare/4)))
        
        row[pos] = actualShare
        remaining = remaining - actualShare
    end
    
    -- Distribute any remaining bricks
    while remaining > 0 do
        local pos = availablePositions[math.random(#availablePositions)]
        row[pos] = row[pos] + 1
        remaining = remaining - 1
    end
    
    unavailableXpos = {}
    local bigBrickLocations = {}
    for xPos, brickHealth in ipairs(row) do
        if brickHealth > 0 then
            if (not bigBrickLocations[xPos-1]) then
                if xPos < 11 and math.random(1, 100) < math.floor(mapRangeClamped(brickCount, 1, 500, 0, 20)) and row[xPos+1] > 0 and not bossSpawned then
                    if (brickHealth + row[xPos+1]) * 2 >= 50 then
                        bigBrickLocations[xPos] = true
                        unavailableXpos[xPos] = true
                        unavailableXpos[xPos+1] = true
                        local bigBrickHealth = math.ceil((brickHealth + row[xPos+1])*2.5)
                        local brickColor = getBrickColor(bigBrickHealth, true)
                        nextRowDebuff = brickHealth + row[xPos+1] -- Set the next row debuff to the health of the big brick
                        table.insert(bricks, {
                            type = "big",
                            id = brickId,
                            x = startLocation + (xPos - 1) * (brickWidth + brickSpacing) + 5 + rowOffset + rowXOffset,
                            y = yPos - (brickHeight + brickSpacing/2),
                            drawOffsetX = 0,
                            drawOffsetY = 0,
                            drawOffsetRot = 0,
                            drawScale = 1,
                            width = brickWidth*2,
                            height = brickHeight*2,
                            destroyed = false,
                            health = bigBrickHealth,
                            maxHealth = bigBrickHealth,
                            colorHealth = bigBrickHealth / 5, -- store the divided value for color
                            color = {brickColor[1], brickColor[2], brickColor[3], 1},
                            hitLastFrame = false,
                            lastHitVfxTime = 0,
                        })
                        brickId = brickId + 1
                        nextRowDebuff = brickHealth + row[xPos+1]
                    end
                elseif Player.level >= 8 and math.random(1, 250) <= math.floor(mapRangeClamped(Player.level, 8, 25, 1, 12)) 
                and not (row.healBrickPositions and (row.healBrickPositions[xPos-1] or row.healBrickPositions[xPos+1])) then
                    if not row.healBrickPositions then row.healBrickPositions = {} end
                    row.healBrickPositions[xPos] = true
                    local brickColor = getBrickColor(brickHealth)
                    local healBrick = {
                        type = "heal",
                        id = brickId,
                        x = startLocation + (xPos - 1) * (brickWidth + brickSpacing) + 5 + rowOffset + rowXOffset,
                        y = yPos,
                        drawOffsetX = 0,
                        drawOffsetY = 0,
                        drawOffsetRot = 0,
                        drawScale = 1,
                        width = brickWidth,
                        height = brickHeight,
                        destroyed = false,
                        health = math.ceil(brickHealth/2),
                        maxHealth = math.ceil(brickHealth/2),
                        color = {brickColor[1], brickColor[2], brickColor[3], 1},
                        hitLastFrame = false,
                        lastHitVfxTime = 0,
                    }
                    table.insert(bricks, healBrick)
                    table.insert(healBricks, healBrick)
                    brickId = brickId + 1
                    local function healSelf(healBrick)
                        if healBrick then
                            if healBrick.health > 0 and healBrick.destroyed ~= true and healBrick.y >= -healBrick.height + 10 then
                                local bricksToHeal = getBricksInCircle(healBrick.x + healBrick.width/2, healBrick.y + healBrick.height/2, healBrick.width* 5/4)
                                for _, brick in ipairs(bricksToHeal) do
                                    -- local brick = healBrick
                                    local healAmount = math.ceil(brick.health/(brick.type == "big" and 160 or 80))
                                    brick.health = brick.health + healAmount
                                    brick.color = getBrickColor(brick.health, brick.type == "big")
                                    healNumber(healAmount, brick.x + brick.width/2, brick.y + brick.height/2)
                                    healThisFrame = healThisFrame + healAmount
                                end
                            end
                            Timer.after(1.75, function() healSelf(healBrick) end)
                        end
                    end
                    Timer.after(1.75 + math.random(1,175)/100, function() healSelf(healBrick) end)
                elseif Player.level >= 12 and math.random(1, 250) <= math.floor(mapRangeClamped(Player.level, 12, 25, 1, 5)) then
                    -- make shield bricks
                    print("Generating shield brick")
                    local shieldHealth = math.ceil(Player.level * 7 + math.random(-100,100)/100 * Player.level)
                    local shieldAura = {
                        type = "shield",
                        id = brickId,
                        x = startLocation + (xPos - 1) * (brickWidth + brickSpacing) + 5 + rowOffset + rowXOffset,
                        y = yPos,
                        drawOffsetX = 0,
                        drawOffsetY = 0,
                        drawOffsetRot = 0,
                        drawScale = 1,
                        width = brickWidth,
                        height = brickHeight,
                        destroyed = false,
                        health = shieldHealth,
                        maxHealth = shieldHealth,
                        color = {1, 1, 1, 1},
                        hitLastFrame = false,
                        lastHitVfxTime = 0,
                        lastSparkleTime = 0
                    }
                    table.insert(shieldAuras, shieldAura)
                    brickId = brickId + 1
                elseif (totalGoldBricksGeneratedThisRun < math.floor((gameTime + 25)/100)) then
                    totalGoldBricksGeneratedThisRun = totalGoldBricksGeneratedThisRun + 1
                    local goldBrick = {
                        type = "gold",
                        id = brickId,
                        x = startLocation + (xPos - 1) * (brickWidth + brickSpacing) + 5 + rowOffset + rowXOffset,
                        y = yPos,
                        drawOffsetX = 0,
                        drawOffsetY = 0,
                        drawOffsetRot = 0,
                        drawScale = 1,
                        width = brickWidth,
                        height = brickHeight,
                        destroyed = false,
                        health = math.ceil(brickHealth/2) * 4,
                        maxHealth = math.ceil(brickHealth/2) * 4,
                        color = {1, 1, 1, 1},
                        hitLastFrame = false,
                        lastHitVfxTime = 0,
                        lastSparkleTime = 0
                    }
                    table.insert(bricks, goldBrick)
                    brickId = brickId + 1                    
                else
                    local brickColor = getBrickColor(brickHealth)
                    table.insert(bricks, {
                        type = "small",
                        id = brickId,
                        x = startLocation + (xPos - 1) * (brickWidth + brickSpacing) + 5 + rowOffset + rowXOffset,
                        y = yPos,
                        drawOffsetX = 0,
                        drawOffsetY = 0,
                        drawOffsetRot = 0,
                        drawScale = 1,
                        width = brickWidth,
                        height = brickHeight,
                        destroyed = false,
                        health = brickHealth,
                        maxHealth = brickHealth,
                        color = {brickColor[1], brickColor[2], brickColor[3], 1},
                        hitLastFrame = false,
                        lastHitVfxTime = 0,
                    })
                    brickId = brickId + 1
                end
            end
        end
    end
    currentRow = currentRow + 1
    return row
end

local bossSpawnTime = 600
--This function is called every 0.5 seconds to see if we should add more bricks, if we should, it adds 10 rows using the generateRow() function
local function addMoreBricks()
    if bricks[#bricks] then
        if bricks[#bricks].y > -50 then
            print("spawning more bricks")
            for i=1 , 10 do
                generateRow(currentRowPopulation, i * -(brickHeight + brickSpacing) - 45) --generate 100 scaling rows of bricks
                local addBrickMult = mapRangeClamped(Player.level, 1, 20, 2, 1)
                currentRowPopulation = currentRowPopulation + gameTime/mapRange(gameTime, 0, 600, 30, 180) 
                if spawnBossNextRow and not bossSpawned then
                    spawnBoss()
                    bossSpawned = true
                    spawnBossNextRow = false
                elseif not (bossSpawned or spawnBossNextRow) and gameTime >= bossSpawnTime then
                    spawnBossNextRow = true
                end
            end
            return
        else 
            return
        end--else print("bricks are too high to spawn more") end
    end
end

local function brickGarbageCollection()
    for i=#bricks, 1, -1 do
        if bricks[i] then
            if bricks[i].destroyed == true then
                table.remove(bricks, i)
            end
        elseif bricks[i] == nil then
            table.remove(bricks, i)
        end
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
    return {hslaToRgba(hue, saturation, lightness, alpha)}
end

function initializeBricks()
    blockedRows = {}
    -- Bricks
    bricks = {}
    shieldAuras = {}
    healBricks = {}
    brickWidth = 75
    brickHeight = 30
    brickSpacing = 10 -- Spacing between bricks
    rows = 3
    cols = 10
    brickSpeed = { value = 10 } -- Speed at which bricks move down (pixels per second)
    currentRowPopulation = Player.currentCore == "Speed Core" and 100 or 1 -- Number of bricks in the first row

    -- Generate bricks
    for i = 0, rows - 1 do
        generateRow(currentRowPopulation, i * -(brickHeight + brickSpacing)) --generate 100 scaling rows of bricks
        currentRowPopulation = currentRowPopulation + (gameTime)/mapRange(gameTime, 0, 600, 15, 150) 
    end

    -- remove the bossSpawnTimer on gameStart if it exists
    if bossBrickSpawnTimer then
        Timer.cancel(bossBrickSpawnTimer)
    end

    --check for adding more bricks every 0.5 seconds
    Timer.every(0.5, function() addMoreBricks() end)

    -- garbage collection every 0.5
    Timer.every(0.5, function() brickGarbageCollection() end)
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
    Player.initialize()
end

local backgroundMusic
local confettiSystem = nil -- Variable to store the confetti system

-- Function to start confetti effect
function startConfetti()
    confettiSystem = confetti.new()
end

-- Function to stop confetti effect
function stopConfetti()
    confettiSystem = nil
end

local backgroundOpacity = {value = 0}
local loadTime
function love.load()
    love.mouse.setVisible(true)
    math.randomseed(os.time())

    WindowCorrector.init(7); -- 5 additional render canvases for shaders and draw order stuff

    dress = suit.new()
    loadAssets() -- Load assets

    -- start menu music
    changeMusic("menu")

    brickFont = love.graphics.newFont(14)    -- Get screen dimensions
    screenWidth, screenHeight = love.graphics.getDimensions()

    gameCanvas = 1; -- enum for windowCorrector canvas --love.graphics.newCanvas(screenWidth, screenHeight)
    uiCanvas = 2; -- enum for windowCorrector canvas --love.graphics.newCanvas(screenWidth, screenHeight)

    -- Render glow canvases at half resolution for performance
    --local glowWidth, glowHeight = math.floor(screenWidth / 2), math.floor(screenHeight / 2)
    glowCanvas = {
        weak = 3; -- enum for windowCorrector canvas --love.graphics.newCanvas(glowWidth, glowHeight, {
        --    format = "rgba8",
        --    msaa = 1
        --}),
        normal = 4; -- enum for windowCorrector canvas --love.graphics.newCanvas(glowWidth, glowHeight, {
        --    format = "rgba8",
        --    msaa = 1
        --}),
        bright = 5; -- enum for windowCorrector canvas --love.graphics.newCanvas(glowWidth, glowHeight, {
        --    format = "rgba8",
        --    msaa = 1
        --})
    }

    -- Create a new canvas for the shader overlay
    shaderOverlayCanvas = 6; -- enum for windowCorrector canvas --love.graphics.newCanvas(screenWidth, screenHeight)

    -- Create temporary canvas for blur
    blurTempCanvas = 7; -- enum for windowCorrector canvas --love.graphics.newCanvas(glowWidth, glowHeight, {format = "rgba8", msaa = 1})

    love.window.setTitle("Brick Breaker")    -- Reset game start time and frozen time tracking

    -- Paddle
    paddle = {
        x = screenWidth / 2 - 50,
        y = screenHeight/2,
        _width = 300, -- Base width + size upgrade
        widthMult = 1,
        height = 20,
        speed = 700, -- Base speed + speed upgrade
        currrentSpeedX = 0,
        speedMult = 1
    }
    setmetatable(paddle, {
        __index = function(t, k)
            if k == "width" then
                print("Accessing paddle.width, hasItem:", hasItem("Huge Paddle"))
                local value = rawget(t, "_width")
                if hasItem("Huge Paddle") then
                    return value * 2
                else
                    return value
                end
            else
                return rawget(t, k)
            end
        end
    })

    loadGameData()
    love.audio.setVolume(globalVolume)
    Crooky:setVisible(not firstRunCompleted)

    backgroundMusic:setVolume(musicVolume/4)
    love.window.setFullscreen(fullScreenCheckbox);

    Crooky:giveInfo("game", "open")
    loadTime = love.timer.getTime()
    
end

function getHighestBrickY(lowestInstead)
    lowestInstead = lowestInstead or false
    -- Defensive: ensure bricks is always a table
    if type(bricks) ~= "table" then bricks = {} end
    local highestY = -math.huge  -- Start with lowest possible number
    for _, brick in ipairs(bricks) do
        if lowestInstead then
            if not brick.destroyed and brick.y < highestY then
                highestY = brick.y
            end
        else
            if not brick.destroyed and brick.y > highestY then
                highestY = brick.y -- + brick.height
            end
        end
    end
    return highestY
end

brickFreeze = false
brickFreezeTime = gameTime
function getBrickSpeedByTime()
    -- Scale speed from 0.5 to 3 over 30 minutes
    local returnValue = mapRange(gameTime, 0, 2000, 0.225, 3) * (Player.currentCore == "Madness Core" and 2 or 1)
    if brickFreeze == true then
        if gameTime - brickFreezeTime > 20 then
            brickFreeze = false
        else
            return 0
        end
    end
    return returnValue
end

function getAverageBrickHealth()
    local totalHealth = 0
    local brickCount = 0
    for _, brick in ipairs(bricks) do
        if not brick.destroyed then
            totalHealth = totalHealth + brick.health
            brickCount = brickCount + 1
        end
    end
    if brickCount == 0 then
        return 0
    else
        return totalHealth / brickCount
    end
end

local startingBrickSpeed = 50
currentBrickSpeed = startingBrickSpeed
deathTweenValues = {speed = 1, overlayOpacity = 0}
function getBrickSpeedMult() 
    -- Get the position-based multiplier
    if Player.dead then
        return deathTweenValues.speed * getBrickSpeedByTime()
    elseif bossSpawned and boss.y >= -boss.height and getHighestBrickY() <= (screenHeight * 3/4 - 250) then
        return mapRangeClamped(boss.y, -boss.height, screenHeight/3, 2.8, 1.35) * getBrickSpeedByTime()
    else
        local posMult = 1
        local highestY = getHighestBrickY()
        posMult = highestY < 350 and mapRangeClamped(highestY, 0, 350, startingBrickSpeed, 10) or mapRangeClamped(highestY, 350, 750, 10, 1.75)
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
end

local function moveBricksDown(dt)
    if UtilityFunction.freeze then
        return -- Don't move bricks at all when frozen
    end
    
    local currentTime = love.timer.getTime()
    local isInHitState = (currentTime - Player.lastHitTime) < 2.0 -- Check if within 2 seconds of hit
    -- Normal speed calculation
    currentBrickSpeed = getBrickSpeedMult()-- < currentBrickSpeed and math.max(currentBrickSpeed - dt * 10, getBrickSpeedMult()) or math.min(currentBrickSpeed + dt * 5, getBrickSpeedMult())
    local speedMult = currentBrickSpeed -- Get the combined speed multiplier
    for _, brick in ipairs(bricks) do
        if not brick.destroyed and brick.health > 0 then
            if brick.type == "gold" then
                if brick.lastSparkleTime then
                    if gameTime - brick.lastSparkleTime >= 0.5 then
                        createSpriteAnimation(brick.x + math.random(0, 100)/100 * brick.width, brick.y + brick.height/4 + math.random(0, 75)/100 * brick.height, 0.35, sparkleVFX, 89, 166, 0.0425, 0, false, 1, 1, 0)
                        brick.lastSparkleTime = gameTime
                    end
                end
            end
            if brick.type == "boss" then
                brick.y = brick.y + brickSpeed.value * dt * speedMult * mapRangeClamped(brick.y, - boss.height * 1.5, -boss.height, 5, 0.5)
            elseif brick.type == "fast" then
                local fastSpeed
                if brick.y <= screenHeight/2 then     
                    fastSpeed = mapRangeClamped(brick.y, 0, screenHeight/2, 100, 50)
                else
                    fastSpeed = mapRangeClamped(brick.y, screenHeight/2, screenHeight, 50, 12)
                end
                brick.y = brick.y + dt * mapRangeClamped(brick.y, 0, screenHeight, 80, 20) * (brick.speedMult or 1)
            else
                brick.y = brick.y + brickSpeed.value * dt * speedMult * (brick.speedMult or 1)
            end
        end
    end

    for _, shield in ipairs(shieldAuras) do
        if not shield.destroyed and shield.health > 0 then
            shield.y = shield.y + brickSpeed.value * dt * speedMult
        end
    end
end

local function reduceBackgroundBrightness()
    -- Reduce background brightness over time, faster at higher intensities
    local reductionRate = 0.01 * (backgroundIntensity * 2) -- Scales from 0.01 to 0.03 based on intensity
    backgroundIntensity = math.max(0, backgroundIntensity - reductionRate)
    -- backgroundShader:send("intensity", backgroundIntensity)
end

screenOffset = {x=0,y=0}

local function brickPiecesUpdate(dt)
    dt = dt * 1.5
    if not Player.levelingUp then
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
    dt = dt/1.5
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

local targetMusicPitch = 1
local currentMusicRef = nil
function changeMusic(newMusicStage)
    if newMusicStage == currentMusicRef then
        return
    end
    if (currentMusicRef == "menu" or currentMusicRef == "calm") and (newMusicStage == "menu" or newMusicStage == "calm") then
        return
    end
    local ref
    if newMusicStage == "menu" then
        ref = "assets/SFX/inGame1.mp3";
        targetMusicPitch = 1;
        BackgroundShader.changeShader(1); -- vexel
        targetMusicVolume = 1
    elseif newMusicStage == "calm" then
        ref = "assets/SFX/inGame1.mp3";
        BackgroundShader.changeShader(1); -- vexel
        targetMusicVolume = 1
    elseif newMusicStage == "mid" then
        ref = "assets/SFX/inGame2.mp3";
        BackgroundShader.changeShader(2); -- acid
    elseif newMusicStage == "intense" then
        ref = "assets/SFX/inGame3.mp3";
        BackgroundShader.changeShader(3); -- vexel
    elseif newMusicStage == "boss" then
        ref = "assets/SFX/inGameBoss.mp3";
        BackgroundShader.changeShader(3); -- vexel
    elseif newMusicStage == "victory" then
        ref = "assets/SFX/victoryTheme.mp3"
        targetMusicVolume = 1
    end
    if backgroundMusic then
        backgroundMusic:stop()
        backgroundMusic = love.audio.newSource(ref, "stream")
        backgroundMusic:setLooping(true)
        backgroundMusic:setVolume(musicVolume/4)
        backgroundMusic:play()
    else
        backgroundMusic = love.audio.newSource(ref, "stream")
        backgroundMusic:setLooping(true)
        backgroundMusic:setVolume(musicVolume/4)
        backgroundMusic:play()
    end
    currentMusicRef = newMusicStage
end

local pausedEffect = {
    type = "lowpass",
    volume = 0.6,
    highgain = 0.04  -- Heavily cut high frequencies
}

local normalEffect = {
    type = "lowpass",
    volume = 1.0,
    highgain = 1.0  -- No cut
}

function setMusicEffect(effect)
    if backgroundMusic then
        if effect == "paused" then
            backgroundMusic:setFilter(pausedEffect)
            targetMusicPitch = 0.97
        elseif effect == "normal" then
            backgroundMusic:setFilter(normalEffect)
            targetMusicPitch = 1
        elseif effect == "dead" then
            backgroundMusic:setFilter(pausedEffect)
            targetMusicPitch = 0.35
        end
    end
end

function setTargetMusicPitch(pitch)
    targetMusicPitch = pitch
end

function setTargetMusicVolume(volume)
    targetMusicVolume = volume
end

local currentMusicVolume = 1
local function updateMusicEffect(dt)
    if backgroundMusic then
        local currentPitch = backgroundMusic:getPitch()
        if math.abs(currentPitch - targetMusicPitch) > 0.01 then
            local pitchChangeRate = 0.4 -- Adjust this value to change how quickly the pitch changes
            if currentPitch < targetMusicPitch then
                currentPitch = math.min(currentPitch + pitchChangeRate * dt, targetMusicPitch)
            else
                currentPitch = math.max(currentPitch - pitchChangeRate * dt, targetMusicPitch)
            end
            backgroundMusic:setPitch(currentPitch)
        end

        local currentVolume = currentMusicVolume
        if math.abs(currentPitch - targetMusicVolume) > 0.01 then
            local volumeChangeRate = 0.5 -- Adjust this value to change how quickly the volume changes
            if currentVolume > targetMusicVolume then
                currentVolume = math.max(currentVolume - volumeChangeRate * dt, targetMusicVolume)
            else
                currentVolume = math.min(currentVolume + volumeChangeRate * dt, targetMusicVolume)
            end
            backgroundMusic:setVolume(musicVolume/4 * currentVolume)
        end
    end
end

local function garbageCollectDynamicObjects()
    if brickPieces then
        cleanTable(brickPieces, function(obj) return obj.destroyed or obj.dead or obj.remove or obj.toRemove end)
    end
    -- Add more as needed for other dynamic object tables
end

shouldTweenAlpha = false
levelUpShopAlpha = 0
function levelUpShopTweenAlpha(dt)
    local tweenSpeed = mapRangeClamped(levelUpShopAlpha, 0, 1, 3, 0.25)
    if shouldTweenAlpha then
        levelUpShopAlpha = 1
        shouldTweenAlpha = false
    end
end

currentlyQueuing = false
brickKilledThisFrame = false
local damageCooldown = 0 -- Cooldown for damage visuals
local healCooldown = 0
local printDrawCalls = false
local function gameFixedUpdate(dt)
    dt = dt * 0.7
    -- Update mouse positions

    levelUpShopTweenAlpha(dt)
    local stats = love.graphics.getStats()
    if printDrawCalls then
        print("Draw calls: " .. stats.drawcallsbatched, 10, 10)
    end

    Crooky:update(dt) -- Update Crooky character

    -- Update confetti system
    if confettiSystem then
        confettiSystem:update(dt)
    end

    updateMusicEffect(dt)
    if currentGameState == GameState.PAUSED then
        return -- Don't update game logic while paused
    end

    if not EventQueue:isQueueFinished() then
        EventQueue:update(dt);

        -- return; -- bugs atm
    end
    
    if currentGameState == GameState.PLAYING then
        
        -- KeywordSystem:update() -- Update the keyword system

        if currentScreenShakeIntensity > 0 then
            screenShakeIntensityDeprecation(dt)
        end

        brickPiecesUpdate(dt) -- Update brick pieces
        -- Garbage collect dynamic objects
        garbageCollectDynamicObjects()
        -- backgroundShader:send("intensity", backgroundIntensity)
        local sineShaderIntensity = 0.3 -- Default base intensity

        dt = dt * playRate -- Adjust the delta time based on the playback rate
        upgradesUI.update(dt) -- Update the upgrades UI
        updateAllTweens(dt) -- Update all tweens


        GlobalTimer:update(dt) -- Update the global timer
        if Player.choosingUpgrade then
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

        if not Player.choosingUpgrade and Player.levelingUp then
            dt = 0
        end

        -- Standard Play logic
        if not Player.choosingUpgrade and not UtilityFunction.freeze and not Player.levelingUp then

            -- Freeze the game if UtilityFunction.freeze and update in game timers
            if UtilityFunction.freeze then
                dt = 0 -- Freeze the game if UtilityFunction.freeze is true
            end
            Timer.update(dt) -- Update the timer
            local function updateGameTime(dt)
                if not UtilityFunction.freeze and not (Player.choosingUpgrade or Player.levelingUp) then
                    gameTime = gameTime + dt / 0.7
                end
            end
            updateGameTime(dt)

            -- fast brick logic
            createFastBrickUpdate()
            fastBricksUpdate()

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
            local leftLimit = usingMoneySystem and statsWidth or 0
            local rightLimit = usingMoneySystem and (screenWidth - statsWidth) or screenWidth
            paddle.x = math.max(leftLimit - (paddle.width/2) + 65, math.min(rightLimit - paddle.width + (paddle.width/2) - 65, paddle.x))
            local bossY = 0
            for _, brick in ipairs(bricks) do
                if brick.type == "boss" then
                    bossY = brick.y + brick.height + 100
                end
            end
            paddle.y = Player.dead and 10000 or math.max(bossY, math.max(math.max(getHighestBrickY() + brickHeight*5, screenHeight/2 + 200), math.min(screenHeight - paddle.height - 10, paddle.y)))
            --paddle.y = 1050
            -- Update Balls
            Balls.update(dt, paddle, bricks, Player)

            -- update damage ripples
            damageRipples.update(dt)

            -- Update explosions
            Explosion.update(dt)
            
            -- Move bricks down
            moveBricksDown(dt)

            boomUpdate(dt) -- Update explosion for damage

            Player.update(dt) -- Update player logic

            updateAnimations(dt) -- Update animations

            if damageCooldown > 0 then
                damageCooldown = damageCooldown - dt -- Reduce damage cooldown
            end

            if healCooldown > 0 then
                healCooldown = healCooldown - dt -- Reduce heal cooldown
            end
            
            if brickKilledThisFrame and damageCooldown <= 0 then
                -- Play brick hit sound effect
                playSoundEffect(brickDeathSFX, 0.15, 1, false, true)
            end
            if not Player.dead then
                damageThisFrame = damageThisFrame or 0 -- Reset damage this frame
                if damageThisFrame > 0 and damageCooldown <= 0 then
                    damageScreenVisuals(mapRangeClamped(damageThisFrame,1,20,0.25, 0.5), damageThisFrame)
                    playSoundEffect(brickHitSFX, math.sqrt(damageThisFrame) >= 4 and mapRangeClamped(math.sqrt(damageThisFrame), 6, 10, 0.6, 1) or mapRangeClamped(math.sqrt(damageThisFrame), 1,6, 0.35, 0.6), math.sqrt(damageThisFrame) >= 5 and mapRangeClamped(math.sqrt(damageThisFrame), 6, 10, 0.75, 1) or  mapRangeClamped(math.sqrt(damageThisFrame),1,6,0.4,0.75), false, true)
                    damageCooldown = 0.03 -- Set cooldown for damage visuals
                    damageThisFrame = 0 -- Reset damage this frame
                end
                brickKilledThisFrame = false -- Reset brick hit state for the next frame
                if healThisFrame > 0 and healCooldown <= 0 then
                    playSoundEffect(healSFX, math.sqrt(healThisFrame) >= 5 and mapRangeClamped(math.sqrt(healThisFrame), 5, 8, 0.25, 0.65) or mapRangeClamped(math.sqrt(healThisFrame), 1, 5, 0.1, 0.4), mapRangeClamped(math.sqrt(healThisFrame), 2, 7, 0.5, 0.8), false, true)
                    healCooldown = 0.07 -- Set cooldown for heal visuals
                    healThisFrame = 0 -- Reset heal this frame
                end
            end
            VFX.update(dt) -- Update VFX
        end
    end    
end

local memLeakCheckTimer = 0
local memLeakLog = ""  -- holds the entire log in memory
local memLeakCheckOn = true

local function memLeakCheck(dt)
    if not memLeakCheckOn then return end
    memLeakCheckTimer = memLeakCheckTimer + dt
    if memLeakCheckTimer > 5 then
        memLeakCheckTimer = 0
        print("Memory Leak Check. Writing output to memoryCheckLog.txt")

        local stats = love.graphics.getStats()

        -- Build log entry
        local logText = "\n----- Memory Leak Check (" .. os.date("%Y-%m-%d %H:%M:%S") .. ") -----\n"
        logText = logText .. string.format("Memory Usage: %.2f MB\n", collectgarbage("count") / 1024)
        logText = logText .. string.format("Draw Calls: %d\n", stats.drawcalls or 0)
        logText = logText .. string.format("Draws Batched: %d\n", stats.drawcallsbatched or 0)

        -- Gather data safely
        local brickPieceAmount, brickAmount, brickTextCacheAmount = 0, 0, 0
        if bricks then
            brickPieceAmount = #brickPieces or 0
            brickAmount = #bricks or 0
            brickTextCacheAmount = tableLength(brickTextCache.objects) or 0
        end

        local visualValuesAmount = (tableLength(visualItemValues) + tableLength(visualUpgradePriceValues) + tableLength(visualStatValues)) or 0
        local tweenAmount = (Tweens and #Tweens) or 0
        local damageNumbersAmount = getDamageNumbersLength() or 0
        local textObjectsAmount = getTextObjectsLength() or 0
        local spriteBatchesAmount = getSpriteBatchesLength() or 0
        local animationAmount = (animations and #animations) or 0
        local quadCacheAmount = getQuadCacheLength() or 0
        local explosionAmount = (explosions and #explosions) or 0
        local fontTableAmount = getFontTableLength() or 0
        local shadowBallCount = getShadowBallCount() or 0
        local fireballCount = getFireballCount() or 0
        local lightBeamCount = getLightBeamCount() or 0
        local arcaneMissileCount = getArcaneMissileCount() or 0
        local shieldAurasAmount = shieldAuras and #shieldAuras or 0

        -- Add formatted info
        logText = logText .. string.format("#Bricks: %d - #Brick Pieces: %d - #Brick Text Cache: %d - #fastBricks: %d - #shieldAuras: %d\n", brickAmount, brickPieceAmount, brickTextCacheAmount, #fastBricks, shieldAurasAmount)
        logText = logText .. string.format("#Tweens: %d - #Visual Values: %d\n", tweenAmount, visualValuesAmount)
        logText = logText .. string.format("#Damage Numbers: %d - #Text Objects: %d\n", damageNumbersAmount, textObjectsAmount)
        logText = logText .. string.format("#Animations: %d - #Sprite Batches: %d - #Quad Cache: %d\n", animationAmount, spriteBatchesAmount, quadCacheAmount)
        logText = logText .. string.format("#Explosions: %d\n", explosionAmount)
        logText = logText .. string.format("#Font Table: %d\n", fontTableAmount)
        logText = logText .. string.format("#Shadow Balls: %d - #Fireballs: %d - #Light Beams: %d - #Arcane Missiles: %d\n", shadowBallCount, fireballCount, lightBeamCount, arcaneMissileCount)

        -- Add this entry to the full log
        memLeakLog = memLeakLog .. logText

        -- Write entire log to file (overwrites old content)
        love.filesystem.write("memoryCheckLog.txt", memLeakLog)

        -- (Optional) print where it's being written
        print(logText)
        print("Log saved to: " .. love.filesystem.getSaveDirectory() .. "/memoryCheckLog.txt")
    end
end


local gcTimer = 0
local memLeakCheckTimer = 0
function love.update(dt)
    gcTimer = gcTimer + dt;
    
    BackgroundShader.update(dt);
    gameFixedUpdate(dt);
    memLeakCheck(dt)
end

local invisButtonColor = {
    normal  = {bg = {0,0,0,0}, fg = {1,1,1}},           -- invisible bg, black fg
    hovered = {bg = {0.19,0.6,0.73,0.2}, fg = {1,1,1}}, -- glowing bg, white fg
    active  = {bg = {1,0.6,0}, fg = {1,1,1}}          -- faint bg, white fg
}

-- Menu settings
local menuFont
local buttonWidth = 400
local buttonHeight = 75
local buttonSpacing = 100
local currentSelectedCoreID = 1
local currentStartingItemID = 1
function getCoreStartingItem(coreName)
    for _, availableCore in ipairs(Player.availableCores) do
        if availableCore.name == coreName then
            return availableCore.startingItem or "ball"
        end
    end
    return "ball"
end
function getCurrentSelectedCore()
    local presetPaddleCores = {}
    for _, core in ipairs(Player.availableCores) do
        local coreName = core.name -- Use core name if available, otherwise use the core itself
        if Player.paddleCores[coreName] then
            table.insert(presetPaddleCores, coreName)
        end
    end 
    return presetPaddleCores[currentSelectedCoreID]
end

function drawMenu()
    -- Calculate center positions
    local centerX = screenWidth / 2 - buttonWidth / 2
    local startY = screenHeight / 2
    
    -- Draw title
    love.graphics.draw(titleImg, screenWidth/2 - titleImg:getWidth()*0.65/2, startY - 500, 0, 0.65, 0.65)

    -- Play button
    local buttonID = generateNextButtonID()
    love.graphics.draw(uiBigWindowImg, screenWidth/2 - uiBigWindowImg:getWidth()/2, startY - 25)
    setFont(50)
    love.graphics.print("Play", screenWidth/2 - getTextSize("Play")/2, startY + 25)
    -- logic for choosing paddle core
    local paddleCores = {}
    for _, core in ipairs(Player.availableCores) do
        local coreName = core.name -- Use core name if available, otherwise use the core itself
        if Player.paddleCores[coreName] then
            table.insert(paddleCores, coreName)
        end
    end 
    local btnY = startY + 125
    setFont(36)
    --suit.Label("Choose your paddle core", {align = "center"}, screenWidth / 2 - getTextSize("Choose your") / 2, btnY - 100)
    local currentSelectedCore = paddleCores[currentSelectedCoreID]
    if not currentSelectedCoreID then currentSelectedCoreID = 1 end
    if not currentSelectedCore then currentSelectedCore = (paddleCores[currentSelectedCoreID] and paddleCores[currentSelectedCoreID].name or "Bouncy Core") end
    setFont(28)
    love.graphics.print(currentSelectedCore, screenWidth/2 - getTextSize(currentSelectedCore) / 2, btnY)
    -- local btn2 = suit.Label(currentSelectedCore, centerX, btnY, buttonWidth, buttonHeight)
    
    setFont(28)
    local core = paddleCores[currentSelectedCoreID]

    -- previous core button
    --love.graphics.draw(uiWindowImg, centerX - 140, btnY, 0, 100 / uiWindowImg:getWidth(), 100 / uiWindowImg:getHeight())
    love.graphics.setColor(0.75,0.75,0.75,1)
    love.graphics.draw(leftArrowImg, centerX - 140, btnY, 0, 100 / leftArrowImg:getWidth(), 100 / leftArrowImg:getHeight())
    love.graphics.setColor(1,1,1,1)
    local btn2Before = suit.Button("", {id = "back_core", color = invisButtonColor, valign = "center"}, centerX - 130, btnY, 100, 100)

    -- next core button
    --love.graphics.draw(uiWindowImg, centerX + buttonWidth + 40, btnY, 0, 100 / uiWindowImg:getWidth(), 100 / uiWindowImg:getHeight())
    love.graphics.setColor(0.75,0.75,0.75,1)
    love.graphics.draw(rightArrowImg, centerX + buttonWidth + 40, btnY, 0, 100 / rightArrowImg:getWidth(), 100 / rightArrowImg:getHeight())
    love.graphics.setColor(1,1,1,1)
    local btn2Next = suit.Button("", {id = "next_core", color = invisButtonColor}, centerX + buttonWidth + 35, btnY, 100, 100)
    
    -- buttons hit logic
    if btn2Next.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentSelectedCoreID = currentSelectedCoreID + 1
        if currentSelectedCoreID > #paddleCores then
            currentSelectedCoreID = 1
        end
        core = paddleCores[currentSelectedCoreID]
        currentSelectedCore = core
    end
    if btn2Before.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentSelectedCoreID = currentSelectedCoreID - 1
        if currentSelectedCoreID < 1 then
            currentSelectedCoreID = #paddleCores
        end
        core = paddleCores[currentSelectedCoreID]
        currentSelectedCore = core.name
    end

    local btnY = btnY + buttonHeight + 80
    local coreDescription = Player.coreDescriptions[core] and Player.coreDescriptions[core] or "No description available"
    suit.Label(coreDescription, {align = "center"}, screenWidth / 2 - 210, btnY - 60, 420, 100)
    local playBtnY = btnY + buttonHeight + 100
    setFont(35)
    local startingItem = "ball"
    for _, availableCore in ipairs(Player.availableCores) do
        if availableCore.name == currentSelectedCore then
            startingItem = availableCore.startingItem or "ball"
            break
        end
    end
    love.graphics.print(startingItem, screenWidth/2 - getTextSize(startingItem) / 2, playBtnY - 65)
    -- suit.Label(startingItem, {align = "center"}, screenWidth / 2 - 225, btnY + 60, 450, 100)
    buttonID = generateNextButtonID()
    if suit.Button("", {id=buttonID, color = invisButtonColor}, screenWidth/2 - uiBigWindowImg:getWidth()/2, startY - 25, uiBigWindowImg:getWidth(), uiBigWindowImg:getHeight()).hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentGameState = GameState.START_SELECT -- Go to selection screen
        love.mouse.setVisible(true)
        -- Crooky:giveInfo("game", "startSelect")

        -- add paddle core select
        playSoundEffect(selectSFX, 1, 0.8)
        startingChoice = startingItem
        startingItemName = startingItem
        Player.currentCore = currentSelectedCore -- Set the selected paddle core
        resetGame()
        currentGameState = GameState.PLAYING
        love.mouse.setVisible(false)
        -- initializeGameState()
        Player.bricksDestroyed = 0 -- Reset bricks destroyed count
        if startingItem ~= "Nothing" and Player.currentCore ~= "Speed Core" then
            Balls.addBall(startingItem)
            print("Adding weapon : " .. startingItem)
        end

        -- crooky logic
        Crooky:giveInfo("run", "start")
    end

    -- Settings button
    love.graphics.draw(uiWindowImg, centerX - screenWidth/4 - 135 + buttonWidth * 0.15,  startY - 40, 0, buttonWidth * 0.7/uiWindowImg:getWidth(), buttonHeight * 1.5/uiWindowImg:getHeight())
    if suit.Button("Settings", {id="menu settings buttons", valign = "middle", color = invisButtonColor}, centerX - screenWidth/4 - 135 + buttonWidth * 0.15, startY - 40, buttonWidth * 0.7, buttonHeight * 1.5).hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentGameState = GameState.SETTINGS
        love.mouse.setVisible(true)
    end

    -- Upgrades button
    love.graphics.draw(uiWindowImg, centerX + screenWidth/4 + 135 + buttonWidth * 0.15, startY - 40, 0, buttonWidth * 0.7/uiWindowImg:getWidth(), buttonHeight * 1.5/uiWindowImg:getHeight())
    if suit.Button("Shop", {id="menu shop button", valign = "middle", color = invisButtonColor}, centerX + screenWidth/4 + 135 + buttonWidth * 0.15, startY - 40, buttonWidth * 0.7, buttonHeight * 1.5).hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentGameState = GameState.UPGRADES
        love.mouse.setVisible(true)
        loadGameData() -- Load game data when entering upgrades screen
    end

    --[[ Wishlist button
    if suit.Button("Wishlist on steam!", {id="wishlist button", align = "center", valign = "middle"}, centerX + buttonWidth * 0.05, startY + (buttonHeight + buttonSpacing) * 3.25, buttonWidth, buttonHeight * 2).hit then
        playSoundEffect(selectSFX, 1, 0.8)
        openBrowser("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    end]]

    -- draw highscore
    suit.Label("Highscore : " .. formatNumber(Player.highScore), {align = "center"}, 50, 50)
    local fastestTime = Player.fastestTime or 1000000
    if fastestTime > 10000 then
        return
    end
    local minutes = math.floor(fastestTime / 60)
    local seconds = math.floor(fastestTime % 60)
    local fastestTimeString = string.format("%02d:%02d", minutes, seconds)
    -- suit.Label(fastestTimeString, {align = "center"}, 100, 150, 200, 30) -- Added position and size parameters
end

local startingItemOrder = {"Ball", "Machine Gun", "Laser Beam", "Shadow Ball"}
local isSpeedCore = false
-- Add a new function for the starting item selection screen
local function drawStartSelect()
    local centerX = screenWidth / 2 - buttonWidth / 2
    local startY = screenHeight / 4
    setFont(36)
    love.graphics.setColor(1, 1, 1, 1)
    suit.Label("Choose your starting item", {align = "center"}, screenWidth / 2 - getTextSize("Choose your starting item") / 2, startY - 100)

    -- Dynamically build the list of unlocked starting items
    local startingItems = {}

    -- build the list of starting paddle cores
    local paddleCores = {}
    for _, core in ipairs(Player.availableCores) do
        local coreName = core.name -- Use core name if available, otherwise use the core itself
        if Player.paddleCores[coreName] then
            table.insert(paddleCores, coreName)
        end
    end

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

    local btnY = startY
    local item = startingItems[currentStartingItemID]
    if paddleCores[currentSelectedCoreID] == "IncrediCore" then
        item = {name = "Incrediball", label = "Incrediball"}
    end
    -- Show the starting item description under the label
    local itemDescription = "No description available for ".. item.label
    if item.label == "Ball" then
        itemDescription = "Basic ball. Very fast."
    elseif item.label == "Machine Gun" then
        itemDescription = "Fires bullets. \nFast fire rate."
    elseif item.label == "Laser Beam" then
        itemDescription = "Fire a thin Laser beam in front of the paddle."
    elseif item.label == "Shadow Ball" then
        itemDescription = "Shoots shadowBalls that pass through bricks. \nVery slow fire rate."
    elseif item.label == "Incrediball" then
        itemDescription = "Has the effects of every other ball (except phantom ball)."
    end
    setFont(36)
    local btn = suit.Label(item.label, {id = item.id}, centerX, btnY, buttonWidth, buttonHeight)
    setFont(25)
    suit.Label(itemDescription, {align = "center"}, centerX-100, btnY + buttonHeight + 10, 600, 60)
    local btnBefore = suit.Button("Back", {id = "back_starting_item"}, centerX - 100 - 20, btnY, 125, buttonHeight)
    local btnNext = suit.Button("Next", {id = "next_starting_item"}, centerX + buttonWidth + 20, btnY, 125, buttonHeight)
    if btnNext.hit then
        playSoundEffect(selectSFX, 1, 0.8)
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
        playSoundEffect(selectSFX, 1, 0.8)
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

    -- logic for choosing paddle core
    btnY = btnY + buttonHeight + 200
    setFont(36)
    suit.Label("Choose your paddle core", {align = "center"}, screenWidth / 2 - getTextSize("Choose your paddle core") / 2, btnY - 80)
    local currentSelectedCore = paddleCores[currentSelectedCoreID]
    if not currentSelectedCoreID then currentSelectedCoreID = 1 end
    if not currentSelectedCore then currentSelectedCore = (paddleCores[currentSelectedCoreID] and paddleCores[currentSelectedCoreID].name or "Bouncy Core") end
    local btn2 = suit.Label(currentSelectedCore, centerX, btnY, buttonWidth, buttonHeight)
    
    setFont(25)
    local core = paddleCores[currentSelectedCoreID]
    local btn2Before = suit.Button("Back", {id = "back_core"}, centerX - 100 - 20, btnY, 125, buttonHeight)
    local btn2Next = suit.Button("Next", {id = "next_core"}, centerX + buttonWidth + 20, btnY, 125, buttonHeight)

    if btn2Next.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentSelectedCoreID = currentSelectedCoreID + 1
        if currentSelectedCoreID > #paddleCores then
            currentSelectedCoreID = 1
        end
        core = paddleCores[currentSelectedCoreID]
        currentSelectedCore = core
    end
    if btn2Before.hit then
        playSoundEffect(selectSFX, 1, 0.8)
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
    suit.Label(coreDescription, {align = "center"}, screenWidth / 2 - 300, btnY - 50, 600, 100)
    local playBtnY = btnY + buttonHeight + 100
    setFont(40)
    local playBtn = suit.Button("Play", {id = "start_play"}, screenWidth / 2 - buttonWidth / 2, playBtnY, buttonWidth, buttonHeight)
    if playBtn.hit then
        changeMusic("calm")
        playSoundEffect(selectSFX, 1, 0.8)
        startingChoice = item.name
        startingItemName = item.name
        Player.currentCore = currentSelectedCore -- Set the selected paddle core
        resetGame()
        currentGameState = GameState.PLAYING
        love.mouse.setVisible(false)
        -- initializeGameState()
        Player.bricksDestroyed = 0 -- Reset bricks destroyed count
        if item.name ~= "Nothing" and Player.currentCore ~= "Speed Core" then
            Balls.addBall(item.name)
        end

        -- crooky logic
        Crooky:giveInfo("run", "start")
    end
end

fakeBossValues = {boost = 0, x = 0, y = 0, on = false}
function drawBricks()
    setFont(18)
    -- Initialize bricks if they don't exist
    if not bricks then 
        bricks = {}
        initializeBricks()
        return
    end
    
    -- Only draw bricks that are on screen (culling)
    local screenTop = 0
    local screenBottom = screenHeight

    
    brickBatch:clear();
    TextBatching.clear();

    local texHeight = love.graphics.getFont():getHeight() / 2;
    
    local brickWidth, brickHeight = brickImg:getDimensions();
    local defColour = {1,1,1,1};
    local goldBricksToDraw = {};
    local bossBrick
    for _, brick in ipairs(bricks) do
        -- skip fast bricks
        if brick.type == "fast" or brick.destroyed then
            goto continue
        end
        if brick.type == "gold" then
            table.insert(goldBricksToDraw, brick);
        elseif brick.type == "boss" then
            bossBrick = brick
        else -- brick is not gold
            brickBatch:setColor(brick.color or defColour);
            brickBatch:add(
                brick.x + (brick.drawOffsetX or 0),
                brick.y + (brick.drawOffsetY or 0),
                0,
                brick.width / brickWidth,
                brick.height / brickHeight
            );
        end
        
        if brick.destroyed or brick.type == "gold" or brick.type == "fast" then
            --? dont draw a brick if its been destroyed
        else -- brick is not gold
            local text = tostring(brick.health);

            TextBatching.addText(
                text,
                brick.x + brick.width / 2 + (brick.drawOffsetX or 0),
                brick.y + brick.height / 2 + (brick.drawOffsetY or 0),
                0,
                1,
                1,
                love.graphics.getFont():getWidth(text) / 2,
                texHeight
            );
        end
        
        ::continue::
    end
    -- setfont(
    love.graphics.draw(brickBatch);
    TextBatching.draw();

    for _, brick in ipairs(goldBricksToDraw) do
        love.graphics.setColor(1,1,1,1);
        love.graphics.draw(
            goldBrickImg,
            brick.x + (brick.drawOffsetX or 0),
            brick.y + (brick.drawOffsetY or 0),
            0,
            brick.width / brickWidth,
            brick.height / brickHeight
        );
    end
    

    -- Draw all gold bricks
    for _, brick in ipairs(goldBricksToDraw) do
        if (not brick.type or brick.type ~= "boss") and not brick.destroyed and brick.y + brick.height > screenTop - 10 and brick.y < screenBottom + 10 then
            local type = brick.type or "small"
            local color = brick.color or {1, 1, 1, 1}
            local scale = brick.drawScale or 1
            local scaleX = scale * (brick.width / brickImg:getWidth())
            local scaleY = scale * (brick.height / brickImg:getHeight())
            local centerX = brick.x + brick.width / 2 + brick.drawOffsetX
            local centerY = brick.y + brick.height / 2 + brick.drawOffsetY
            
            -- Draw brick
            if brick.type == "gold" then
                love.graphics.setColor(1,1,1,1)
                love.graphics.draw(goldBrickImg, centerX, centerY, brick.drawOffsetRot, scaleX, scaleY, brickImg:getWidth() / 2, brickImg:getHeight() / 2)
            else
                love.graphics.setColor(color)
                love.graphics.draw(brickImg, centerX, centerY, brick.drawOffsetRot, scaleX, scaleY, brickImg:getWidth() / 2, brickImg:getHeight() / 2)
            end
            
            -- Draw health text (black outline)
            local text = tostring(brick.health)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(text, centerX, centerY, 0, 1, 1, love.graphics.getFont():getWidth(text) / 2, love.graphics.getFont():getHeight() / 2)
            
            -- Draw health text (white)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(text, centerX, centerY, 0, 1, 1, love.graphics.getFont():getWidth(text) / 2, love.graphics.getFont():getHeight() / 2)
        end
    end

    if bossBrick then
        local brick = bossBrick
        local color = brick.color
        local scale = brick.drawScale or 1
        -- Calculate scale to fit the brick width/height exactly
        local scaleX = brick.width / bossBrickImg:getWidth()
        local scaleY = brick.height / bossBrickImg:getHeight()
        local centerX = brick.x + brick.width / 2 + brick.drawOffsetX + 3
        local centerY = brick.y + brick.height / 2 + brick.drawOffsetY
        love.graphics.setColor(color)
        -- Draw from center of image and brick
        love.graphics.draw(bossBrickImg, centerX, centerY, brick.drawOffsetRot, scaleX, scaleY, bossBrickImg:getWidth() / 2, bossBrickImg:getHeight() / 2)
        -- love.graphics.setColor(1,1,1, fakeBossValues.boost)
        -- love.graphics.draw(bossBrickOverlayImg, centerX, centerY, brick.drawOffsetRot, scaleX, scaleY, bossBrickImg:getWidth() / 2, bossBrickImg:getHeight() / 2)

        setFont(50)
        -- Draw health text (black outline)
        local text = tostring(brick.health)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(text, centerX, centerY, 0, 1, 1, love.graphics.getFont():getWidth(text) / 2, love.graphics.getFont():getHeight() / 2)
        
        -- Draw health text (white)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(text, centerX, centerY, 0, 1, 1, love.graphics.getFont():getWidth(text) / 2, love.graphics.getFont():getHeight() / 2)

        drawImageCentered(crownImg, centerX, centerY - brick.height / 2, crownImg:getWidth()/2.5, crownImg:getHeight()/2.5)
    end

    if fakeBossValues.on then
        local color = getBrickColor(1)
        local scale = 1
        -- Calculate scale to fit the brick width/height exactly
        local scaleX = bossWidth / bossBrickImg:getWidth()
        local scaleY = bossHeight / bossBrickImg:getHeight()
        local centerX = fakeBossValues.x + bossWidth / 2 + 3
        local centerY = fakeBossValues.y + bossHeight / 2
        love.graphics.setColor(color)
        love.graphics.draw(bossBrickImg, centerX, centerY, 0, scaleX, scaleY, bossBrickImg:getWidth() / 2, bossBrickImg:getHeight() / 2)
        love.graphics.setColor(1,1,1, fakeBossValues.boost)
        love.graphics.draw(bossBrickOverlayImg, centerX, centerY, 0, scaleX, scaleY, bossBrickImg:getWidth() / 2, bossBrickImg:getHeight() / 2)
    end

    -- draw fastBricks
    setFont(18);
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)

    for _, fastBrick in ipairs(fastBricks) do
        if fastBrick.health <= 0 or fastBrick.destroyed then
            goto continue
        end
        -- draw trail
        -- draw fading trail
        if fastBrick.trail and #fastBrick.trail > 0 then
            local trailCount = #fastBrick.trail
            local baseColor = {fastBrick.color[1], fastBrick.color[2], fastBrick.color[3], 1}
            for i, pt in ipairs(fastBrick.trail) do
                local t = 1 - (i - 1) / trailCount -- 1 = newest, 0 = oldest

                local alpha = 0.2 * t -- fade from subtle to strong
                local realW = fastBrick.width
                local w = fastBrick.width * t * 0.9
                local h = fastBrick.height * t
                love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], alpha)
                love.graphics.rectangle("fill", pt.x + (realW - w)/2, pt.y, w, h)
            end
            love.graphics.setColor(1, 1, 1, 1)
        end

        if not fastBrick.destroyed then
            love.graphics.setColor(fastBrick.color);
            love.graphics.draw(
                brickImg,
                fastBrick.x + (fastBrick.drawOffsetX or 0),
                fastBrick.y + (fastBrick.drawOffsetY or 0),
                0,
                fastBrick.width / brickWidth,
                fastBrick.height / brickHeight
            );
            local text = tostring(fastBrick.health);
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(
                text,
                fastBrick.x + fastBrick.width / 2 + (fastBrick.drawOffsetX or 0),
                fastBrick.y + fastBrick.height / 2 + (fastBrick.drawOffsetY or 0),
                0,
                1,
                1,
                love.graphics.getFont():getWidth(text) / 2,
                texHeight
            );
        end
        ::continue::
    end

    -- draw heal symbol on healBricks
    for i = #healBricks, 1, -1 do
        local brick = healBricks[i]
        if not (brick.destroyed or brick.health <=0) then
            love.graphics.setColor(125/255, 1, 0, 1)
            love.graphics.draw(healImg, brick.x + brick.width/2 + 10 + brick.drawOffsetX, brick.y + brick.height/2 -15 + brick.drawOffsetY, 0, 0.75, 0.75)
            love.graphics.setColor(1,1,1,1)
        else
            table.remove(healBricks, i)
        end
        love.graphics.setColor(0 ,1 ,0 , 0.5)
        drawImageCentered(healAuraImg, brick.x + brick.width/2, brick.y + brick.height/2,brick.width * 3.25, brick.width * 3.25)
    end

    -- draw shield auras
    for _, aura in ipairs(shieldAuras) do
        love.graphics.setColor(0,104/255,161/255,1)
        drawImageCentered(healAuraImg, aura.x + aura.width/2, aura.y + aura.height/2,aura.width * 6.5, aura.width * 6.5)
        setFont(45)
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(tostring(aura.health), aura.x + aura.width/2 - getTextSize(aura.health) / 2 -1, aura.y + aura.height/2 - 21)
        love.graphics.print(tostring(aura.health), aura.x + aura.width/2 - getTextSize(aura.health) / 2 -1, aura.y + aura.height/2 - 19)
        love.graphics.print(tostring(aura.health), aura.x + aura.width/2 - getTextSize(aura.health) / 2 +1, aura.y + aura.height/2 - 21)
        love.graphics.print(tostring(aura.health), aura.x + aura.width/2 - getTextSize(aura.health) / 2 +1, aura.y + aura.height/2 - 19)
        love.graphics.setColor(0,174/255,211/255,1)
        love.graphics.print(tostring(aura.health), aura.x + aura.width/2 - getTextSize(aura.health) / 2, aura.y + aura.height/2 - 20)
    end

    -- Draw brick pieces (not batched)
    for _, brickPiece in ipairs(brickPieces) do
        love.graphics.setColor(brickPiece.color)
        love.graphics.draw(brickPiece.img, brickPiece.x, brickPiece.y, 0, brickPiece.width / brickPiece.img:getWidth(), brickPiece.height / brickPiece.img:getHeight())
    end
end

local frozenTime = 0
local lastFreezeTime = 0
local useTime = true

local function drawGameTimer()
    if useTime then
        local countdownTime = bossSpawnTime - gameTime
        local minutes = math.floor(countdownTime / 60)
        local seconds = math.floor(countdownTime % 60)
        local timeString = string.format("%02d:%02d", minutes, seconds)
        
        -- Draw timer
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(timeString)
        local x = screenWidth / 2 - textWidth / 2
        local y = screenHeight - 175
        
        love.graphics.setColor(1, 1, 1, 1)
        setFont(80)
        if countdownTime >= 0 then
            love.graphics.print(timeString, x, y)
        end
        if playRate ~= 1 then
            setFont(24)
            love.graphics.print(string.format(playRate) .. "X", x + textWidth + 10, y + 50)
        end
    end
end

function restartGame()
    changeMusic("calm")
    local goldEarned = Player.level * math.ceil(Player.level / 5) * 5 
    local startingItem = getCoreStartingItem(Player.currentCore)
    playSoundEffect(selectSFX, 1, 0.8)
    Player.addGold(goldEarned)
    saveGameData()
    resetGame()
    if startingItem ~= "Nothing" and Player.currentCore ~= "Speed Core" then
        Balls.addBall(startingItem)
    end
    currentGameState = GameState.PLAYING 
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
        if not (Player.levelingUp or Player.choosingUpgrade) then
            setMusicEffect("normal")
        end
        playSoundEffect(selectSFX, 1, 0.8)
        currentGameState = GameState.PLAYING
        love.mouse.setVisible(false)
    end
    btnY = btnY + buttonHeight + 30
    -- Settings button (does nothing for now)
    local settingsBtn = suit.Button("Settings", {id="pause_settings"}, centerX, btnY, buttonWidth, buttonHeight)
    if settingsBtn.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        currentGameState = GameState.SETTINGS
        love.mouse.setVisible(true)
    end
    btnY = btnY + buttonHeight + 30
    -- Restart button (same as play again)
    local startingItem = getCoreStartingItem(Player.currentCore)
    local restartBtn = suit.Button("Restart", {id="pause_restart"}, centerX, btnY, buttonWidth, buttonHeight)
    local goldEarned = Player.level * math.ceil(Player.level / 5) * 5 
    if restartBtn.hit then
        restartGame()
    end
    btnY = btnY + buttonHeight + 30
    -- Main Menu button
    local menuBtn = suit.Button("Main Menu", {id="pause_menu"}, centerX, btnY, buttonWidth, buttonHeight)
    if menuBtn.hit then
        playSoundEffect(selectSFX, 1, 0.8)
        Player.addGold(goldEarned)
        saveGameData()
        resetGame()
        currentGameState = GameState.MENU
        love.mouse.setVisible(true)
        setMusicEffect("normal")
    end
    btnY = btnY + buttonHeight + 30
    -- Exit Game button
    local exitBtn = suit.Button("Exit Game", {id="pause_exit"}, centerX, btnY, buttonWidth, buttonHeight)
    if exitBtn.hit then
        playSoundEffect(selectSFX, 1, 0.8)
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
    love.graphics.printf("Gold earned : " .. tostring(goldEarnedFrl), 0, centerY - 30, screenWidth, "center")
    love.graphics.setColor(1, 1, 1, 1) -- White for Time
    love.graphics.printf("Time : " .. string.format("%02d:%02d", math.floor(gameTime / 60), math.floor(gameTime % 60)), 0, centerY + 20, screenWidth, "center")
    love.graphics.setColor(1.0, 0.6, 0.2, 1) -- Light orange for Bricks Destroyed
    love.graphics.printf("Bricks Destroyed : " .. tostring(Player.bricksDestroyed), 0, centerY + 70, screenWidth, "center")
    setFont(28)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    love.graphics.printf("Press R to restart or ESC to quit", 0, centerY + 2000, screenWidth, "center")

    -- Draw Main Menu, Keep Going, and Upgrades buttons at the bottom using SUIT
    local buttonW, buttonH = 350, 125
    local spacing = 40  -- Reduced spacing to fit three buttons
    local totalWidth = buttonW * 3 + spacing * 2  -- Width for three buttons
    local startX = (screenWidth - totalWidth) / 2 
    local y = screenHeight * 3/4
    setFont(36)

    --[[ Keep Going button (new)
    if suit.Button("Keep Going", {id = "keep_going"}, startX, y, buttonW, buttonH).hit then
        changeMusic("intense")
        playSoundEffect(selectSFX, 1, 0.8)
        currentGameState = GameState.PLAYING  -- Set state back to playing
        love.mouse.setVisible(false)
    end]]

    -- Main Menu button
    if suit.Button("Main Menu", {id = "victory_menu"}, startX + buttonW + spacing, y, buttonW, buttonH).hit then
        -- changeMusic("menu")
        playSoundEffect(selectSFX, 1, 0.8)
        resetGame()
        currentGameState = GameState.MENU
        love.mouse.setVisible(true)
    end
    -- Upgrades button
    if suit.Button("Shop", {id = "victory_upgrades"}, startX + (buttonW + spacing) * 2, y, buttonW, buttonH).hit then
        -- changeMusic("menu")
        playSoundEffect(selectSFX, 1, 0.8)
        resetGame()
        currentGameState = GameState.UPGRADES
        love.mouse.setVisible(true)
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

inGame = false
globalVolume = 1
-- Add a function to draw the settings menu with SUIT sliders
function drawSettingsMenu()
    local centerX = screenWidth / 2 - buttonWidth / 2
    local startY = screenHeight / 2 - (buttonHeight * 2 + buttonSpacing * 2.5) / 2
    setFont(48)
    love.graphics.setColor(1, 1, 1, 1)
    local title = "Settings"
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, screenWidth/2 - titleWidth/2, startY - 125)

    setFont(36)
    local sliderWidth = 400
    local sliderHeight = 40
    local sliderSpacing = 80
    local sliderX = screenWidth/2 - sliderWidth/2
    local sliderY = startY + 100

    -- Master / global volume slider (affects all audio via the mixer)
    suit.Label("Master Volume", {align = "left"}, sliderX, sliderY - sliderSpacing, sliderWidth, 40)
    local masterSliderInfo = { value = globalVolume or 1 }
    local masterSlider = suit.Slider(masterSliderInfo, { id = "master_volume_slider" }, sliderX, sliderY + 40 - sliderSpacing, sliderWidth, sliderHeight)
    globalVolume = masterSliderInfo.value
    -- Apply to love audio mixer so music & sfx are scaled globally
    love.audio.setVolume(globalVolume)

    -- Music Volume Slider
    local musicSliderInfo = {value = musicVolume}
    suit.Label("Music Volume", {align = "left"}, sliderX, sliderY, sliderWidth, 40)
    local musicSlider = suit.Slider(musicSliderInfo, {id = "music_slider"}, sliderX, sliderY + 40, sliderWidth, sliderHeight)
    musicVolume = musicSliderInfo.value
    if backgroundMusic then
        backgroundMusic:setVolume(musicVolume/4) -- Adjust the volume of the background music
    else
        print("Background music not found")
    end
    --print("Music Volume: " .. musicVolume)

    -- SFX Volume Slider
    local prevSfxValue = sfxVolume
    local sfxSliderInfo = {value = sfxVolume}
    suit.Label("SFX Volume", {align = "left"}, sliderX, sliderY + sliderSpacing, sliderWidth, 40)
    local sfxSlider = suit.Slider(sfxSliderInfo, {id = "sfx_slider"}, sliderX, sliderY + sliderSpacing + 40, sliderWidth, sliderHeight)
    sfxVolume = sfxSliderInfo.value

    -- Track if mouse button was just released while hovering the slider
    if prevSfxValue ~= sfxVolume and love.mouse.isDown(1) then
        playSoundEffect(selectSFX, sfxVolume, 1, false)
    end

    local prevChecked = fullScreenCheckbox;
    local checkboxInfo = {checked = fullScreenCheckbox};
    suit.Label("Fullscreen", {align = "left"}, sliderX, sliderY + sliderSpacing * 2, sliderWidth, 40);
    local fullScreenTickBox = suit.Checkbox(checkboxInfo, {id = "fullscreen_checkbox"}, sliderX, sliderY + sliderSpacing * 2 + 40, 40, 40);
    fullScreenCheckbox = checkboxInfo.checked;

    if fullScreenCheckbox ~= prevChecked then
        love.window.setFullscreen(fullScreenCheckbox);
    end

    local prevDamageNumbersOn = damageNumbersOn;
    local dmgNumCheckboxInfo = {checked = damageNumbersOn};
    suit.Label("Damage Numbers", {align = "left"}, sliderX, sliderY + sliderSpacing * 2 + 80, 50000, 40);
    sliderY = sliderY + sliderSpacing
    local damageNumbersTickBox = suit.Checkbox(dmgNumCheckboxInfo, {id = "damage_numbers_checkbox"}, sliderX, sliderY + sliderSpacing * 2 + 40, 40, 40);
    damageNumbersOn = dmgNumCheckboxInfo.checked;

    -- Back button
    local backBtn = suit.Button("Back", {id="settings_back"}, sliderX, sliderY + sliderSpacing * 5 + 20, sliderWidth, buttonHeight)
    if backBtn.hit then
        saveGameData()
        playSoundEffect(selectSFX, 1, 0.8)
        if inGame then
            currentGameState = GameState.PAUSED
            love.mouse.setVisible(true)
        else
            currentGameState = GameState.MENU
            love.mouse.setVisible(true)
        end
    end
end

local function fullDraw()
    BackgroundShader.draw();

    resetButtonLastID()
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Draw level progress bar at the bottom
    if currentGameState == GameState.PLAYING then
        -- Progress bar background
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        if usingMoneySystem then
            love.graphics.rectangle("fill", statsWidth, screenHeight - 30, screenWidth - statsWidth*2, 30)
        else
            love.graphics.rectangle("fill", 0, screenHeight - 30, screenWidth, 30)
        end

        -- Progress bar fill
        local farmCoreMult = (Player.currentCore == "Farm Core" and 2 or 1)
        local progress = Player.xp / (Player.xpForNextLevel * farmCoreMult)
        love.graphics.setColor(90/255, 150/255, 0.75, 1)
        if usingMoneySystem then
            love.graphics.rectangle("fill", statsWidth, screenHeight - 30, 
                (screenWidth - statsWidth*2) * math.min(1, math.max(0, progress)), 30)
        else
            love.graphics.rectangle("fill", 0, screenHeight - 30, 
                screenWidth * math.min(1, math.max(0, progress)), 30)
        end

        -- Level text
        love.graphics.setColor(1, 1, 1, 1)
        setFont(25)
        local levelText = "Lvl " .. Player.level
        local textWidth = love.graphics.getFont():getWidth(levelText)
        if usingMoneySystem then
            love.graphics.print(levelText, statsWidth + 15, screenHeight - 25)
        else
            love.graphics.print(levelText, 15, screenHeight - 25)
        end

        
    end

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
        if not firstRunCompleted and false then
            Crooky:draw()
        end
        local opacity = mapRange(love.timer.getTime() - loadTime, 0, 2.5, 1, 0)
        love.graphics.setColor(0,0,0, opacity)
        love.graphics.rectangle("fill", -screenWidth, -screenHeight, screenWidth*3, screenHeight*3)
        return
    end
    
    if currentGameState == GameState.START_SELECT then
        drawStartSelect()
        setFont(30)
        if suit.Button("Back", {color = invisButtonColor}, 20, 20, uiLabelImg:getWidth()*0.8, uiLabelImg:getHeight()*0.8).hit then
            playSoundEffect(selectSFX, 1, 0.8)
            currentGameState = GameState.MENU
            love.mouse.setVisible(true)
        end
        if suit.Button("Shop", {color = invisButtonColor}, screenWidth - uiLabelImg:getWidth()*0.8 - 20, 20, uiLabelImg:getWidth()*0.8, uiLabelImg:getHeight()*0.8).hit then
            playSoundEffect(selectSFX, 1, 0.8)
            currentGameState = GameState.UPGRADES
            love.mouse.setVisible(true)
        end
        suit.draw()
        if not firstRunCompleted and false then
            Crooky:draw()
        end
        return
    end

    if currentGameState == GameState.UPGRADES then
        loadGameData() -- Load game data

        -- Draw SUIT UI elements
        suit.draw()
        -- Draw permanent upgrades
        permanentUpgrades.draw()

        setFont(30)
        if suit.Button("Back", {color = invisButtonColor}, 20, 20, uiLabelImg:getWidth()*0.8, uiLabelImg:getHeight()*0.8).hit then
            playSoundEffect(selectSFX, 1, 0.8)
            currentGameState = GameState.MENU
            love.mouse.setVisible(true)
        end
        if suit.Button("Play", {color = invisButtonColor}, screenWidth - uiLabelImg:getWidth()*0.8 - 20, 20, uiLabelImg:getWidth()*0.8, uiLabelImg:getHeight()*0.8).hit then
            changeMusic("calm")
            playSoundEffect(selectSFX, 1, 0.8)
            currentGameState = GameState.START_SELECT
            love.mouse.setVisible(true)
        end

        if not firstRunCompleted and false then
            Crooky:draw()
        end
        return
    end

    if currentGameState == GameState.VICTORY then
        drawVictoryScreen()
        return
    end

    if currentGameState == GameState.SETTINGS then
        drawSettingsMenu()
        suit.draw()
        return
    end

    -- reset keyword system tooltip each frame
    -- KeywordSystem:resetTooltip()

    -- First render the game to the game canvas
    WindowCorrector.startDrawingToCanvas(gameCanvas);
    --love.graphics.setCanvas(gameCanvas) -- Set the canvas for drawing
    love.graphics.clear()
    love.graphics.push()

    love.graphics.translate(screenOffset.x, screenOffset.y) -- Apply screen shake

    -- Draw game objects to glow canvases (at lower resolution)
    WindowCorrector.startDrawingToCanvas(glowCanvas.bright);
    --love.graphics.setCanvas(glowCanvas.bright)
    --love.graphics.clear()
    love.graphics.push()
    --love.graphics.scale(0.5, 0.5) -- Downscale drawing for half-res canvas
    love.graphics.setColor(1, 1, 1, 1)

    --love.graphics.setCanvas(glowCanvas.bright)
    love.graphics.clear()
    -- Draw the paddle
    love.graphics.draw(paddleImg, paddle.x, paddle.y - 2, 0,  paddle.width/250, 1)
    -- love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height)
    
    love.graphics.pop()

    love.graphics.push()
    --love.graphics.scale(0.5, 0.5)
    if currentGameState == GameState.PLAYING then
        drawBricks() -- Draw bricks
    end
    love.graphics.pop()

    --love.graphics.setCanvas(glowCanvas.bright)
    love.graphics.push()
    --love.graphics.scale(0.5, 0.5)
    love.graphics.setColor(1, 1, 1, 1)
    Balls:draw() -- Draw balls
    love.graphics.pop()
    --love.graphics.setCanvas()
    WindowCorrector.stopDrawingToCanvas();

    -- Apply glow effect and draw to main canvas
    love.graphics.setColor(1,1,1,1)
    WindowCorrector.startDrawingToCanvas(gameCanvas);
    --love.graphics.setCanvas(gameCanvas)
    love.graphics.setShader(glowShader)

    -- draw bright canvas for glow effect
    glowShader:send("resolution", {screenWidth, screenHeight})
    glowShader:send("intensity", 1.25)
    WindowCorrector.mergeCanvases(gameCanvas, glowCanvas.bright);
    --love.graphics.draw(glowCanvas.bright, 0, 0, 0, 2, 2)
    --love.graphics.setBlendMode("alpha") -- ! was weird, watch out if was needed
    love.graphics.setShader()
    
    -- Now draw the paddle and other objects solid
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(paddleImg, paddle.x, paddle.y - 2, 0,  paddle.width/250, 1)
    -- love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height)
    drawBricks()
    Balls.draw(Balls)
    drawPopups()

    -- damageRipples.draw()

    love.graphics.setColor(1, 1, 1, 1)
    for i=1, Player.lives do
        --love.graphics.draw(heartImg, -20, 75 + ((heartImg:getHeight()*2 + 5)*(i-1)), 0, 4, 4)
    end
    WindowCorrector.startDrawingToCanvas(gameCanvas);
    --love.graphics.setCanvas(gameCanvas)
    -- love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height)
    --love.graphics.draw(glowCanvas.bright)

    -- Draw explosions
    Explosion.draw()

    drawDamageNumbers() -- Draw damage numbers

    drawAnimations() -- Draw animations

    drawMuzzleFlashes() -- Draw muzzle flashes
    
    love.graphics.pop()
    
    -- Draw the game timer
    drawDamageNumbers()
    if gameTime < 600 then
        drawGameTimer()
    end
    if Player.levelingUp then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setColor(1, 1, 1, 1)
    end

    drawAnimations()
    drawMuzzleFlashes()

    local vignetteIntensity = mapRangeClamped(screenHeight - paddle.y, 0 , 110, 0.8, 0)
    love.graphics.setColor(0.15, 0, 0, vignetteIntensity)
    love.graphics.draw(vignetteImg, 0, 0, 0)
    upgradesUI.draw()

    -- Draw the UI elements using Suit
    suit.draw()
    

    if (not firstRunCompleted) and currentGameState == GameState.PLAYING and false then
        Crooky:draw()
    end

    -- why is this not being displayed in front of Player.money???????
    drawMoneyPopups()

    drawPausedUpgradeNumbers()

    if Player.dead then
        -- draw deathOverlay
        love.graphics.setColor(0, 0, 0, deathTweenValues.overlayOpacity)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        if deathTimerOver then
            GameOverDraw()
        end
    end
    if Player.choosingUpgrade then
        drawLevelUpShop()
    end

    dress:draw()    -- Draw tooltip last (on top of everything)
    -- KeywordSystem:drawTooltip()
    confetti:draw()

    -- draw borders for when the game is in windowed mode
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", -1000, -1000, 1000, 4000)
    love.graphics.rectangle("fill", screenWidth, -1000, 1000, 4000) 
    
    WindowCorrector.startDrawingToCanvas(gameCanvas);
    --love.graphics.setCanvas(gameCanvas)
    VFX.draw() -- Draw VFX
    WindowCorrector.stopDrawingToCanvas();
    --love.graphics.setCanvas()

    -- Draw the game canvas gameCanvasfirst
    love.graphics.setColor(1, 1, 1, 1)
    WindowCorrector.mergeCanvas(gameCanvas);
    --love.graphics.draw(gameCanvas)
    
    -- Then draw the shader overlay on top with some transparency to blend with the game
    love.graphics.setColor(1, 1, 1, 1.0) -- Adjust alpha for desired effect
    --love.graphics.draw(shaderOverlayCanvas)

    -- draw ui canvas
    WindowCorrector.mergeCanvas(uiCanvas);
    --love.graphics.draw(uiCanvas)
    drawFPS()

    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
    setFont(20)
end

function love.draw()
    fullDraw();

    if gcTimer > 0.5 then
        -- collectgarbage("collect")
        -- print("Memory (KB): " .. collectgarbage("count"))
        -- local drawStats = love.graphics.getStats();
        -- print("draw calls :" .. tostring(drawStats.drawcalls));
        -- print("texture mem:" .. tostring(drawStats.texturememory));
        gcTimer = 0
    end
end

function finishUpgrading()
    playSoundEffect(selectSFX, 1, 0.8)
    itemsOnLevelUpEnd()
    Player.levelingUp = false
    for _, ballType in pairs(Balls.getUnlockedBallTypes()) do
        if ballType.type == "ball" then
            Balls.adjustSpeed(ballType.name)
        end
    end
    if Player.level == 8 then
        changeMusic("mid")
    elseif Player.level == 16 then
        changeMusic("intense")
    end
    setMusicEffect("normal")
    love.mouse.setVisible(false)

    -- crooky logic
    if Player.level == 2 and not firstRunCompleted then
        Crooky:giveInfo("run", "firstLevelUpEnd")
    end
end

damageNumbersOn = true
healNumbersOn = true
ballTrailsOn = true
local testingMode = false
local old_love_keypressed = love.keypressed
moneyScale = {scale = 1}
function love.keypressed(key)
    if key == "space" and Player.levelingUp and (not Player.choosingUpgrade) and EventQueue:isQueueFinished() then
        if currentlyOnFirstLevelUp then
            if Player.getCurrentTutorialStep() == 2 then
                EventQueue:addEventToQueue(EVENT_POINTERS.levelUp, 0);
                if hasItem("Birthday Hat") then
                    EventQueue:addEventToQueue(EVENT_POINTERS.levelUp, 0);
                end
                Player.InterestGain()
            end
            if Player.getCurrentTutorialStep() ~= 4 then
                Player.nextTutorialStep()
            end
        else
            finishUpgrading()
        end
    end

    if key == "escape" then
        if currentGameState == GameState.PLAYING then
            playSoundEffect(selectSFX, 1, 0.8)
            if not Player.dead then
                setMusicEffect("paused")
            end
            currentGameState = GameState.PAUSED
            love.mouse.setVisible(true)
            return
        elseif currentGameState == GameState.PAUSED then
            if not (Player.levelingUp or Player.choosingUpgrade) then
                love.mouse.setVisible(false)
                setMusicEffect("normal")
            end
            playSoundEffect(selectSFX, 1, 0.8)
            currentGameState = GameState.PLAYING
            love.mouse.setVisible(true)
            return
        elseif currentGameState == GameState.SETTINGS then
            saveGameData()
            playSoundEffect(selectSFX, 1, 0.8)
            if inGame then
                currentGameState = GameState.PAUSED
                love.mouse.setVisible(true)
            else
                currentGameState = GameState.MENU
                love.mouse.setVisible(true)
            end
            return
        elseif currentGameState == GameState.START_SELECT or currentGameState == GameState.UPGRADES then
            playSoundEffect(selectSFX, 1, 0.8)
            currentGameState = GameState.MENU
            love.mouse.setVisible(true)
            return
        else
            love.event.quit()
            return
        end
    end

    if key == "t" then 
        testingMode = not testingMode
        print("Testing mode: " .. tostring(testingMode))
    end

    if testingMode then

        -- PERFORMANCE STRESS TESTS

        --[[if key == "q" then
            for i=1, 100 do
                local speedRef = 2500
                local speedXref = math.random(-1000,1000)
                local bullet = {
                    name = "Gun Ball",
                    type = "bullet",
                    x = math.random(50, screenWidth - 50),
                    y = screenHeight/2 + math.random(0, screenHeight/2 - 10),
                    speedX = speedXref,
                    speedY = -math.sqrt(math.abs(speedRef*speedRef - speedXref - speedXref)),
                    radius = 5,
                    stats = {damage = 1},
                    hasSplit = false,
                    hasTriggeredOnBulletHit = false,
                    golden = (Player.currentCore == "Phantom Core" or hasItem("Phantom Bullets")),
                }
                Balls.insertBullet(bullet)
            end
        end]]
        if key == "x" then
            for i=1, 500 do
                local randomBrickIdx = math.random(1, #bricks)
                local dmgBrick = bricks[randomBrickIdx]
                if dmgBrick then
                    if dmgBrick.health > 0 and dmgBrick.destroyed ~= true and dmgBrick.y >= -dmgBrick.height + 10 then
                        local bricksToDamage = getBricksInCircle(dmgBrick.x + dmgBrick.width/2, dmgBrick.y + dmgBrick.height/2, dmgBrick.width* 5/4)
                        for _, brick in ipairs(bricksToDamage) do
                            -- local brick = healBrick
                            brick.health = brick.health - 1
                            brick.color = getBrickColor(brick.health, brick.type == "big")
                            damageNumber(1, brick.x + brick.width/2, brick.y + brick.height/2)
                            brick.color = getBrickColor(brick.health, brick.type == "big")
                        end
                    end
                end
            end
        end
        if key == "c" then
            for i=1, 500 do
                local randomBrickIdx = math.random(1, #bricks)
                local healBrick = bricks[randomBrickIdx]
                if healBrick then
                    if healBrick then
                        if healBrick.health > 0 and healBrick.destroyed ~= true and healBrick.y >= -healBrick.height + 10 then
                            local bricksToHeal = getBricksInCircle(healBrick.x + healBrick.width/2, healBrick.y + healBrick.height/2, healBrick.width* 5/4)
                            for _, brick in ipairs(bricksToHeal) do
                                -- local brick = healBrick
                                local healAmount = math.ceil(brick.health/(brick.type == "big" and 160 or 80))
                                brick.health = brick.health + healAmount
                                brick.color = getBrickColor(brick.health, brick.type == "big")
                                healNumber(healAmount, brick.x + brick.width/2, brick.y + brick.height/2)
                                healThisFrame = healThisFrame + healAmount
                            end
                        end
                    end
                end
            end
        end

        -- destroy all bricks under half screen Height
        if key == "0" then
            for i= #bricks, 1, -1 do
                local brick = bricks[i]
                if not brick.destroyed and brick.y > screenHeight/5 then
                    dealDamage({stats = {damage = 10000000}}, brick)
                end
            end
        end

        -----------------------------------

        if key == "1" then
            firstRunCompleted = true
        end

        if key == "2" then
            Timer.every(0.035, function()
                playSoundEffect(shieldBlockSFX, 1, 1, false)
            end)
        end
        if key == "3" then
            damageThisFrame = 50
        end

        if key == "4" then
            createMoneyPopup(3 ,paddle.x + paddle.width/2, paddle.y, 1000)
        end

        -- get powerup
        if key == "5" then
            local powerup = {
                type = "acceleration",        
            }
            powerupPickup(powerup, 1)
        end

        -- create powerup
        if key == "6" then
            createPowerupG("acceleration")
        end

        -- add weapon
        if key == "7" then  
            Balls.addBall("Golden Gun")
        end

        if key == "8" then
            Player.level = Player.level - 1
        end

        if key == "9" then
            spawnBoss()
        end

        -- PERFORMANCE TEST ON OFF BLOCK

        if key == "v" then
            damageNumbersOn = not DamageNumbersOn
        end
        if key == "b" then
            healNumbersOn = not healNumbersOn
        end
        if key == "r" then
            dmgVFXOn = not dmgVFXOn
        end
        if key == "w" then
            canHeal = not canHeal
        end

        -----------------------------------

        -- level up
        if key == "e" then
            Player.levelUp()
        end

        if key == "u" then
            createSpriteAnimation(500, 500, 1.25, fireballVFX, 64, 64, 0.075, 0, false, 1, 1, 0, nil, nil, nil, 8)
        end

        if key == "p" then
            currentGameState = GameState.VICTORY
            love.mouse.setVisible(true)
        end

        -- brickHitVFX
        if key == "z" then
            for i=1, 150 do
                Timer.after(i * 0.025, function()
                    for _, brick in ipairs(bricks) do
                        if not brick.destroyed then
                            brickHitFX(brick, nil, 1)
                        end
                    end
                end)
            end
        end

        -- freeze
        if key == "f" then
            toggleFreeze()
        end

        --money manipulation
        if key == "m" then
            -- local moneyBefore = Player.money
            Player.changeMoney(10); -- gain 10 money
            -- gainMoneyWithAnimations(10);
            -- Player.money = Player.money < 10 and 10 or Player.money * 10
            -- richGetRicherUpdate(moneyBefore, Player.money)
        end
        if key == "n" then
            -- local moneyBefore = Player.money

            Player.setMoney(0);
            -- Player.money = 0
            -- richGetRicherUpdate(moneyBefore, Player.money)
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

        --test ball hit vfx
        if key == "y" then
            for _,ball in ipairs(Balls) do
                ballHitVFX(ball)
            end
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
            for i=1, 2000 do
                local x, y = math.random(screenWidth/5, screenWidth*4/5), math.random(screenHeight/5, screenHeight*4/5)
                createSpriteAnimation(x, y, 1, explosionVFX, 512, 512, 0.01, 0, false)
            end
        end
    end
end

function love.mousepressed(x, y, button)
    if button == 2 then
        if hoveringPlayerItem then
            print("Selling item: " .. hoveringPlayerItem)
            for i, item in ipairs(Player.items) do
                if item.id == hoveringPlayerItem or item.name == hoveringPlayerItem then
                    local sellValue = item.rarity == "common" and 4 or
                                      item.rarity == "uncommon" and 8 or
                                      item.rarity == "rare" and 12 or
                                      item.rarity == "legendary" and 16 or 0
                    Player.changeMoney(sellValue)
                    playSoundEffect(selectSFX, 1, 0.8)
                    table.remove(Player.items, i)
                    break
                end
            end
        end
    end
end

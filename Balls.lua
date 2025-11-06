-- This file holds the values for all the Balls in the game.
-- It also holds the functions for updating the Balls and drawing them.
local Smoke = require("particleSystems.smoke")
local Explosion = require("particleSystems.explosion")
local ArcaneMissile = require("particleSystems.arcaneMissile")
local FlameBurst = require("particleSystems.flameBurst")

startingBall = "Machine Gun" -- The first ball that is added to the game 
local Balls = {}
local ballCategories = {}
local ballList = {}
local bouncyCoreSpeedBoost = 5

function Balls.getBallList()
    return ballList
end
local unlockedBallTypes = {}
local nextBallPrice = 100
function Balls.getNextBallPrice()
    return nextBallPrice
end
function Balls.NextBallPriceIncrease()
    nextBallPrice = nextBallPrice * 10
end

function Balls.getUnlockedBallTypes()
    return unlockedBallTypes
end

function Balls.clearUnlockedBallTypes()
    unlockedBallTypes = {}
end

local burningBricksCooldown = {}
local damageTimers = {}
local fireAnims = {}
local fireTimers = {}
local lightningCooldowns = {} -- Table to track per-brick cooldowns for lightning spells

local function burnBricksEnd(brickID)
    if not brickID then return end

    -- Cancel timers
    if damageTimers[brickID] then
        Timer.cancel(damageTimers[brickID])
        damageTimers[brickID] = nil
    end

    -- Clear the burning state
    burningBricksCooldown[brickID] = nil

    -- Handle animation cleanup
    local anim = fireAnims[brickID]
    if anim then
        local animation = getAnimation(anim)
        if animation and animation.color then
            local fadeOutTween = tween.new(0.25, animation.color, {1,1,1,0}, tween.outCubic)
            addTweenToUpdate(fadeOutTween)
            Timer.after(0.25, function()
                removeAnimation(anim)
                fireAnims[brickID] = nil
            end)
        else
            removeAnimation(anim)
            fireAnims[brickID] = nil
        end
    end
end

local function burnBrick(brick, damage, length, name)
    --[[if not brick or not brick.id then return end

    -- If brick is already burning, refresh duration and cancel old timer
    if burningBricksCooldown[brick.id] then
        burningBricksCooldown[brick.id] = math.max(burningBricksCooldown[brick.id], length)
        return
    elseif fireAnims[brick.id] then
        removeAnimation(fireAnims[brick.id])
        fireAnims[brick.id] = nil
    end

    -- Set up new burn effect
    burningBricksCooldown[brick.id] = length

    -- Create fire animation
    fireAnims[brick.id] = createSpriteAnimation(brick.x + brick.width / 2, brick.y + brick.height / 2, 2, fireVFX, 32, 32, 0.05, 0, true, 1, 1, 0, {1,1,1,0},true, brick.id)
    local animation = getAnimation(fireAnims[brick.id])
    if animation then
        local fireStartTween = tween.new(0.25, animation.color, {1,1,1,1}, tween.outCubic)
        addTweenToUpdate(fireStartTween)
    end

    -- Set up damage timer
    damageTimers[brick.id] = Timer.every(0.75, function()
        if brick and brick.health and brick.health > 0 and burningBricksCooldown[brick.id] then
            dealDamage({stats = {damage = 1}, name = name}, brick, true)
        else
            burnBricksEnd(brick.id)
        end
    end)]]
end

local function bossDestroyed()
    inGame = false
    firstRunCompleted = true
    print("Boss destroyed! Triggering victory.")
    for _, b in ipairs(bricks) do
        b.destroyed = true
    end
    victoryAchieved = true
    bossSpawned = false
    currentGameState = GameState.VICTORY
    love.mouse.setVisible(true)
    -- Award gold and save data (same as game over)
    local goldEarned = 500 + Player.level * math.ceil(Player.level / 5) * 5 
    goldEarnedFrl = goldEarned
    Player.gold = (Player.gold or 0) + goldEarned
    if gameTime < (Player.fastestTime or 1000000) then
        Player.fastestTime = gameTime
    end
    if Player.score > (Player.highScore or 0) then
        Player.highScore = Player.score
        newHighScore = true
    end
    if saveGameData then saveGameData() end
    if savePermanentUpgrades then savePermanentUpgrades() end
end

function FarmCoreUpgrade()
    local i = 1
    local item = nil
    for itemName, _ in pairs(unlockedBallTypes) do
        item = unlockedBallTypes[itemName]
        local randomStat = nil
        local statTable = {}
        for statName, statValue in pairs(item.stats) do
            statTable[statName] = statValue
            if item.name == "Saw Blades" then
                print("stat name = " .. statName)
            end
        end
        if item.noAmount == false then
            statTable["amount"] = (item.amount or 1)
        end
        if item then    
            local doItAgain = true
            while doItAgain do
                local randomStatIndex = math.random(1, tableLength(statTable))
                local i = 1
                for statName, bruh in pairs(statTable) do
                    if i == randomStatIndex then
                        if not (statName == "cooldown" and ((item.stats.cooldown or -1000) + getStatItemsBonus(statName, item) + (Player.permanentUpgrades.cooldown or 0)) <=0) then
                            doItAgain = false
                            randomStat = statName
                            print("statName = " .. statName .. " - value = ".. formatNumber(bruh))
                            break -- Get the first stat name
                        end
                    end
                    i = i + 1
                end
            end
        end

        if item and randomStat then
            print("Farm Core: Giving " .. item.name .. " a boost to " .. randomStat)
            if randomStat == "cooldown" then
                item.stats[randomStat] = math.max(0, (item.stats[randomStat] or 0) - 1) -- Decrease cooldown
            elseif randomStat == "speed" then
                item.stats[randomStat] = (item.stats[randomStat] or 0) + 50 -- Increase speed
                if item.type == "ball" then
                    Balls.adjustSpeed(item)
                end
            elseif randomStat == "ammo" then
                item.stats[randomStat] = (item.stats[randomStat] or 0) + (item.ammoMult or 1)
            elseif randomStat == "amount" and item.type == "ball" then
                Balls.addBall(item.name, true)
                item.ballAmount = (item.ballAmount or 0) + 1
            else
                print("random stat = ".. randomStat)
                item.stats[randomStat] = (item.stats[randomStat] or 0) + 1 -- Increase other stats
            end
        end
    end
end

function totalUpgrade()
    local i = 1
    local item = nil
    for itemName, _ in pairs(unlockedBallTypes) do
        item = unlockedBallTypes[itemName]
        local randomStats = {}
        local statTable = {}
        for statName, statValue in pairs(item.stats) do
            statTable[statName] = statValue
            if item.name == "Saw Blades" then
                print("stat name = " .. statName)
            end
        end
        if item.noAmount == false then
            statTable["amount"] = (item.amount or 1)
        end
        if item then    
            local doItAgain = true
            while doItAgain do
                for statName, bruh in pairs(statTable) do
                    if not (statName == "cooldown" and ((item.stats.cooldown or -1000) + getStatItemsBonus(statName, item) + (Player.permanentUpgrades.cooldown or 0)) <=0) then
                        doItAgain = false
                        table.insert(randomStats, statName)
                        print("statName = " .. statName .. " - value = ".. formatNumber(bruh))
                        break -- Get the first stat name
                    end
                end
            end
        end

        if item and randomStat then
            print("Farm Core: Giving " .. item.name .. " a boost to " .. randomStat)
            if randomStat == "cooldown" then
                item.stats[randomStat] = math.max(0, (item.stats[randomStat] or 0) - 1) -- Decrease cooldown
            elseif randomStat == "speed" then
                item.stats[randomStat] = (item.stats[randomStat] or 0) + 50 -- Increase speed
                if item.type == "ball" then
                    Balls.adjustSpeed(item)
                end
            elseif randomStat == "ammo" then
                item.stats[randomStat] = (item.stats[randomStat] or 0) + (item.ammoMult or 1)
            elseif randomStat == "amount" and item.type == "ball" then
                Balls.addBall(item.name, true)
            else
                print("random stat = ".. randomStat)
                item.stats[randomStat] = (item.stats[randomStat] or 0) + 1 -- Increase other stats
            end
        end
    end
end

local powerups = {}
-- Powerup trail ring-buffer settings (prevents per-frame allocations and table shifting)
local POWERUP_TRAIL_MAX = 5         -- max stored trail points per powerup
local POWERUP_TRAIL_SPACING = 0.08  -- seconds between new trail points
local powerupColors = {
    freeze = {},
    moneyBag = {},
    nuke = {},
    doubleSpeed = {},
    doubleAmount = {},
    doubleDamage = {},
    doubleRange = {},
    doubleFireRate = {},
    
}
local function createPowerup(x, y, amount, type)
    local powerup = {
        x = x,
        y = y,
        type = type,
        angle = 0,
        bounceAmount = 0,
        amount = amount,
        radius = amount <= 20 and mapRangeClamped(amount, 1, 20, 4, 6) or (amount <= 125 and mapRangeClamped(amount, 20, 125, 6, 8) or mapRangeClamped(amount, 125, 500, 8, 10)),
        speedX = math.random(-75, 75),
        speedY = -250,
        gravity = 400,
        lifetime = 10,
        trail = {}, -- preallocated below
        creationTime = gameTime,
        -- ring-buffer metadata
        _trailHead = 1,
        _trailCount = 0,
        _lastTrailTime = 0,
    }
    -- pre-allocate small point tables to avoid per-frame allocations
    for i = 1, POWERUP_TRAIL_MAX do
        powerup.trail[i] = { x = 0, y = 0, alpha = 0 }
    end
    table.insert(powerups, powerup)
end

function createPowerupss(amount)
    for i=1, amount do
        createPowerup(math.random(100, screenWidth-100), math.random(100, screenHeight-100), math.random(1, 100))
    end
end

local function getRandomPowerupType()
    local powerupTypes = {"moneyBag", "nuke", "acceleration", "doubleDamage"}
    local powerup = powerupTypes[math.random(#powerupTypes)] 
    --[[if getHighestBrickY() < screenHeight - 400 then
        local powerupTypesNoFreeze = {"moneyBag", "nuke", "acceleration", "doubleDamage"}
        powerup = powerupTypesNoFreeze[math.random(#powerupTypesNoFreeze)]
    end]]
    return powerup
end

brickPieces = {}
local currentMoneyDropChance = 0
local function brickDestroyed(brick)
    Player.bricksDestroyed = (Player.bricksDestroyed or 0) + 1
    local chance = hasItem("Four Leafed Clover") and 40 or 20

    -- Victory logic: if boss brick is destroyed, destroy all bricks and trigger victory
    if brick and brick.type == "boss" then
        bossDestroyed()
        return
    end
    for ballName, ballType in pairs(unlockedBallTypes) do
        if ballType.onBrickDestroyed then
            ballType.onBrickDestroyed()
        end
    end
    local brickPiece1 = {
        x = brick.x,
        y = brick.y,
        speedX = math.random(-100, -50), -- Random speed for the piece
        speedY = -math.random(50, 100), -- Random speed for the piece
        img = brickPiece1Img,
        width = brick.width,
        height = brick.height / 2,
        color = {0.75, 0.75, 0.75, 1}
    }
    local brickPiece2 = {
        x = brick.x,
        y = brick.y + brick.height / 2,
        speedX = math.random(-25, 50), -- Random speed for the piece
        speedY = -math.random(50, 100), -- Random speed for the piece
        img = brickPiece2Img,
        width = brick.width,
        height = brick.height / 2,
        color = {0.75, 0.75, 0.75, 1}
    }
    local brickPiece3 = {
        x = brick.x + brick.width / 2,
        y = brick.y,
        speedX = math.random(50, 100), -- Random speed for the piece
        speedY = -math.random(50, 100), -- Random speed for the piece
        img = brickPiece3Img,
        width = brick.width / 2,
        height = brick.height,
        color = {0.75, 0.75, 0.75, 1}
    }
    local tween1 = tween.new(0.8, brickPiece1, {color = {0.75, 0.75, 0.75, 0}}, tween.outCubic)
    local tween2 = tween.new(0.8, brickPiece2, {color = {0.75, 0.75, 0.75, 0}}, tween.outCubic)
    local tween3 = tween.new(0.8, brickPiece3, {color = {0.75, 0.75, 0.75, 0}}, tween.outCubic)
    addTweenToUpdate(tween1)
    addTweenToUpdate(tween2)
    addTweenToUpdate(tween3)
    table.insert(brickPieces, brickPiece1)
    table.insert(brickPieces, brickPiece2)
    table.insert(brickPieces, brickPiece3)

    Player.gain(brick.maxHealth)
    if brick.type == "gold" then
        local type = getRandomPowerupType()
        createPowerup(brick.x + brick.width / 2, brick.y + brick.height / 2, brick.maxHealth, type)
    end

    local chanceMult = 1
    if hasItem("Scavenger") then
        for i=1, itemCount("Scavenger") do
            chanceMult = chanceMult + 0.5
        end
    end
    if math.random(1,4000)/chanceMult <= currentMoneyDropChance then
        createPowerup(brick.x + brick.width / 2, brick.y + brick.height / 2, brick.maxHealth, "dollarBill")
        currentMoneyDropChance = 0
    else
        currentMoneyDropChance = currentMoneyDropChance + 1
    end
end

function BrickDestroyedGlobal(brick)
    brick.health = 0
    brickDestroyed(brick)
    brick = nil
end

function Balls.reduceCooldown(typeName) 
    --unlockedBallTypes[typeName].currentCooldown = math.max(0, unlockedBallTypes[typeName].currentCooldown - 1)
end

function Balls.reduceAllCooldowns()
    --[[for typeName, ballType in pairs(unlockedBallTypes) do
        ballType.currentCooldown = math.max(0, ballType.currentCooldown - 1)
    end]]
end



-- reduce trail length to make draw cheaper (was 35)
local ballTrailLength = 15   -- Length of the ball trail
local bullets = {}
local deadBullets = {}
local laserBeamBrick
local laserBeamY = 0

local brickDeathSFXCd = 0
-- Update damage calculation in dealDamage function score
-- Pre-allocate color tables at module level
local RED_COLOR = {1, 0, 0, 1}
local YELLOW_COLOR = {1, 1, 0, 1}

function dealDamage(ball, brick, burnDamage)

    if Player.dead then return end
    if not ball or not brick then return false end
    
    local burnDamage = burnDamage or false
    local kill = false
    
    
    local damage = ball.stats.damage
    if unlockedBallTypes[ball.name] then
        damage = damage + getStatItemsBonus(statName, ballList[ball.name]) + (Player.permanentUpgrades["damage"] or 0)
    end
    
    local isPhantomBullet = ball.type == "bullet" and hasItem("Phantom Bullets")
    if ball.type == "bullet" then
        damage = ball.stats.damage
        if isPhantomBullet then
            damage = math.max(math.ceil(damage / 2), 1)
        end
    end
    
    if (Player.currentCore == "Brickbreaker Core" or hasItem("Brickbreaker")) and brick.type ~= "boss" then
        local critChance = hasItem("Four Leafed Clover") and (brick.type == "big" and 10 or 20) or (brick.type == "big" and 4 or 8) 
        if math.random(1,100) < critChance then
            damage = math.max(damage, brick.health)
        end
    end
    
    if Player.currentCore == "Damage Core" and ball.type ~= "bullet" then
        damage = damage * 5
    end

    if Player.currentCore == "Madness Core" and ball.type ~= "bullet" then
        damage = math.floor(damage / 2)
    end

    local critChance = hasItem("Four Leafed Clover") and 50 or 25
    if hasItem("Assassin's Dagger") and math.random(1,100) <= critChance and ball.type ~= "bullet" then
        damage = damage * 2
    end
    if statDoubled == "damage" and ball.type ~= "bullet" then
        damage = damage * 2
    end
    
    damage = math.floor(damage)
    damage = math.min(damage, brick.health)
    brick.health = math.ceil(brick.health - damage)
    
    if ball.name ~= "Gold Ball" then
        local xOffset = math.random(-brick.width * 0.25, brick.width * 0.25)
        local yOffset = math.random(-brick.height * 0.25, brick.height * 0.25)
        damageNumber(damage, brick.x + brick.width * 0.5 + xOffset, brick.y + brick.height * 0.5 + yOffset, RED_COLOR)
    end
    
    if unlockedBallTypes[ball.name] then
        unlockedBallTypes[ball.name].damageDealt = (unlockedBallTypes[ball.name].damageDealt or 0) + damage
    end
    
    if brick.type == "big" then
        brick.color = getBrickColor(brick.health, true)
    else
        brick.color = getBrickColor(brick.health, false, false)
    end
    
    damageThisFrame = (damageThisFrame or 0) + damage
    VFX.brickHit(brick, ball, damage)
    
    if usingNormalXpSystem and false then
        Player.gain(damage)
    end
    
    if brick.health >= 1 then
        brick.hitLastFrame = true
        if ball.name == "Flamethrower" and not burnDamage then
            burnBrick(brick, damage, 2, "Flamethrower")
        end
    else
        kill = true
        brickKilledThisFrame = true
        brick.destroyed = true
        
        if ball.type == "bullet" and not ball.golden then
            if (not (ball.name == "Golden Gun" or ball.golden or Player.currentCore == "Phantom Core")) then
                ball.stats.damage = ball.stats.damage - damage
                if ball.stats.damage <= 0 then
                    kill = false
                    ball = nil
                end
            end
        end
    end
    
    if kill then
        brickDestroyed(brick)
        brick = nil
    elseif brick and brick.health <= 0 then
        brickDestroyed(brick)
        brick = nil
    end
    
    return kill
end

local shootSFXCooldown = 0
-- Update bullet damage in shoot function
local function shoot(gunName, ball)
    if Player.dead then
        return
    end   
    if ball ~= nil then
        if gunName == "Gun Ball" or gunName == "Gun Ball Gun" or gunName == "Incrediball" then
            print("gun name " .. gunName)
            local gun = unlockedBallTypes[gunName]
            -- Always calculate bulletDamage as a number, never a boolean
            local bulletDamage = getStat(gunName, "damage")
            if Player.currentCore == "Phantom Core" then
                bulletDamage = math.max(math.floor(bulletDamage / 2), 1)
            end
            local bulletSpeed = gun.bulletSpeed or 1000
            local angle = math.random(0, 360) * math.pi / 180
            local speedXref = math.cos(angle) * bulletSpeed
            local speedYref = math.sin(angle) * bulletSpeed
            if shootSFXCooldown <= 0 then
                playSoundEffect(gunShootSFX, 0.8, 0.8, false, true)
                shootSFXCooldown = 0.05
            end
            local critChance = hasItem("Four Leafed Clover") and 50 or 25
            table.insert(bullets, {
                name = "Gun Ball",
                type = "bullet",
                x = ball.x,
                y = ball.y,
                speedX = speedXref,
                speedY = speedYref,
                radius = 5,
                stats = {damage = bulletDamage * ((hasItem("Assassin's Dagger") and math.random(1,100) <= critChance) and 2 or 1)},
                hasSplit = false,
                hasTriggeredOnBulletHit = false,
                golden = (Player.currentCore == "Phantom Core" or hasItem("Phantom Bullets")),
            })
            local chance = hasItem("Four Leafed Clover") and 20 or 10
            if math.random(1,100) <= chance and hasItem("Sudden Mitosis") then
                local totalSpeed = 500
                local speedX = math.random(-totalSpeed*0.6, totalSpeed*0.6)
                local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
                local ballTemplate = ballList["Ball"]
                local newBall = {
                    type = "ball",
                    name = ballTemplate.name,
                    x = paddle.x + paddle.width / 2,
                    y = paddle.y - 6,
                    speedMult = ballTemplate.speedMult or 1,
                    radius = (ballTemplate.radius or 10) * 1.5,
                    drawSizeBoost = 1,
                    drawSizeMult = 0.5,
                    drawSizeBoostTweens = {},
                    onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                    currentlyOverlappingBricks = {},
                    attractionStrength = ballTemplate.attractionStrength or nil,
                    stats = ballTemplate.stats,
                    speedX = speedX,
                    speedY = speedY,
                    dead = false,
                    trail = {},
                    speedMultiplier = 1
                }
                table.insert(Balls, newBall)
                Timer.after(8, function()
                    local ballDeathTween = tween.new(0.5, newBall, {drawSizeMult = 0}, tween.outCubic)
                    addTweenToUpdate(ballDeathTween)
                    Timer.after(0.5, function()
                        for i, b in ipairs(Balls) do
                            if b == newBall then
                                table.remove(Balls, i)
                                break
                            end
                        end 
                    end)
                end)
            end
            return
        end
    end
    local spray = hasItem("Spray and Pray")
    if unlockedBallTypes[gunName] then
        local bulletStormMult = Player.perks.bulletStorm and 2 or 1
        local gun = unlockedBallTypes[gunName]
        if gun.currentAmmo > 0 or gun.name == "Ball Gun" or gun.name == "Gun Ball Gun" then
            for _, ballType in pairs(unlockedBallTypes) do
                if ballType.onShoot then
                    -- If this is Flame Burst, set the triggering gun name for cooldown tracking
                    if ballType.name == "Flame Burst" then
                        ballType._triggeringGunName = gunName
                    end
                    ballType.onShoot()
                end
            end
            if shootSFXCooldown <= 0 then
                playSoundEffect(gunShootSFX, 0.8, 0.8, false, true)
                shootSFXCooldown = 0.05
            end
            local speedOffset = (paddle.currentSpeedX or 0) * 0.4
            local bulletDamage = getStat(gun.name, "damage")
            if Player.currentCore == "Phantom Core" then
                bulletDamage = math.max(math.floor(bulletDamage * 0.5), 1) -- Phantom Core cuts the damage in 3
            end
            local bulletSpeed = gun.bulletSpeed or 1000

            -- decrease ammo
            if gun.name ~= "Ball Gun" and gun.name ~= "Gun Ball Gun" then
                gun.currentAmmo = gun.currentAmmo - 1
            end

            -- shoot function for each different gun and default
            if gun.name == "Ball Gun" then
                for i = 1, getStat(gun.name, "amount") do
                    local totalSpeed = getStat("Ball Gun", "speed") * 1.5
                    local speedX = math.random(-totalSpeed*0.6, totalSpeed*0.6)
                    local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
                    local ballTemplate = unlockedBallTypes[gunName]
                    local newBall = {
                        type = "ball",
                        name = ballTemplate.name,
                        x = paddle.x + paddle.width / 2,
                        y = paddle.y - 6,
                        speedMult = ballTemplate.speedMult or 2,
                        radius = (ballTemplate.radius or 10) * 1.5,
                        drawSizeBoost = 1,
                        drawSizeMult = 0,
                        drawSizeBoostTweens = {},
                        onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                        currentlyOverlappingBricks = {},
                        attractionStrength = ballTemplate.attractionStrength or nil,
                        stats = ballTemplate.stats,
                        speedX = speedX,
                        speedY = speedY,
                        dead = false,
                        trail = {},
                        speedMultiplier = 1
                    }
                    table.insert(Balls, newBall)
                    local ballSpawnTween = tween.new(0.2, newBall, {drawSizeMult = 0.5}, tween.outCubic)
                    addTweenToUpdate(ballSpawnTween)
                    Timer.after(5, function()
                        local ballDeathTween = tween.new(0.5, newBall, {drawSizeMult = 0}, tween.outCubic)
                        addTweenToUpdate(ballDeathTween)
                        Timer.after(0.5, function()
                            for i, b in ipairs(Balls) do
                                if b == newBall then
                                    table.remove(Balls, i)
                                    break
                                end
                            end 
                        end)
                    end)
                end
                Balls.adjustSpeed("Ball Gun")
                -- Ball Gun specific behavior
            elseif gun.name == "Gun Ball Gun" then
                for i = 1, getStat(gun.name, "amount") do
                    local totalSpeed = getStat(gun.name, "speed")
                    local speedX = math.random(-totalSpeed * 0.6, totalSpeed * 0.6)
                    local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
                    local ballTemplate = unlockedBallTypes[gunName]
                    local newBall = {
                        type = "ball",
                        name = "Gun Ball",
                        x = paddle.x + paddle.width / 2,
                        y = paddle.y - 6,
                        speedMult = ballTemplate.speedMult or 1,
                        radius = (ballTemplate.radius or 10) * 1.5,
                        drawSizeBoost = 1,
                        drawSizeMult = 0,
                        drawSizeBoostTweens = {},
                        onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                        currentlyOverlappingBricks = {},
                        attractionStrength = ballTemplate.attractionStrength or nil,
                        stats = ballTemplate.stats,
                        color = ballTemplate.color or {0.8, 0.4, 0.1, 1},
                        speedX = speedX,
                        speedY = speedY,
                        dead = false,
                        trail = {},
                        speedMultiplier = 1
                    }
                    table.insert(Balls, newBall)
                    local ballSpawnTween = tween.new(0.2, newBall, {drawSizeMult = 0.5}, tween.outCubic)
                    addTweenToUpdate(ballSpawnTween)
                    Timer.after(6, function()
                        local ballDeathTween = tween.new(0.5, newBall, {drawSizeMult = 0}, tween.outCubic)
                        addTweenToUpdate(ballDeathTween)
                        Timer.after(0.5, function()
                            for i, b in ipairs(Balls) do
                                if b == newBall then
                                    table.remove(Balls, i)
                                    break
                                end
                            end 
                        end)
                    end)
                end
            elseif gun.name == "Shotgun" then
                for i = 1, 7 do
                    local speedXref = spray and (math.random(-gun.bulletSpeed * 0.8, gun.bulletSpeed * 0.8) + speedOffset) or (math.random(-250, 250) + speedOffset)
                    local critChance = hasItem("Four Leafed Clover") and 50 or 25
                    table.insert(bullets, {
                        name = "Shotgun",
                        type = "bullet",
                        x = paddle.x + paddle.width / 2 + ((speedXref-speedOffset)/(spray and gun.bulletSpeed * 0.8 or 250)) * 50,
                        y = paddle.y,
                        speedX = speedXref + math.random(-90, 90),
                        speedY = -math.sqrt(bulletSpeed^2 - (speedXref + math.random(-80, 80))^2),
                        radius = 5,
                        stats = {damage = bulletDamage * ((hasItem("Assassin's Dagger") and math.random(1,100) <= critChance) and 2 or 1)},
                        hasSplit = false,
                        hasTriggeredOnBulletHit = false,
                        golden = (gun.name == "Golden Gun" or (Player.currentCore == "Phantom Core" or hasItem("Phantom Bullets"))),
                    })
                end
                local chance = hasItem("Four Leafed Clover") and 20 or 10
                if math.random(1,100) <= chance and hasItem("Sudden Mitosis") then
                    local totalSpeed = 500
                    local speedX = math.random(-totalSpeed*0.6, totalSpeed*0.6)
                    local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
                    local ballTemplate = ballList["Ball"]
                    local newBall = {
                        type = "ball",
                        name = ballTemplate.name,
                        x = paddle.x + paddle.width / 2,
                        y = paddle.y - 6,
                        speedMult = ballTemplate.speedMult or 1,
                        radius = (ballTemplate.radius or 10) * 1.5,
                        drawSizeBoost = 1,
                        drawSizeMult = 0.5,
                        drawSizeBoostTweens = {},
                        onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                        currentlyOverlappingBricks = {},
                        attractionStrength = ballTemplate.attractionStrength or nil,
                        stats = ballTemplate.stats,
                        speedX = speedX,
                        speedY = speedY,
                        dead = false,
                        trail = {},
                        speedMultiplier = 1
                    }
                    table.insert(Balls, newBall)
                    Timer.after(8, function()
                        local ballDeathTween = tween.new(0.5, newBall, {drawSizeMult = 0}, tween.outCubic)
                        addTweenToUpdate(ballDeathTween)
                        Timer.after(0.5, function()
                            for i, b in ipairs(Balls) do
                                if b == newBall then
                                    table.remove(Balls, i)
                                    break
                                end
                            end 
                        end)
                    end)
                end
            elseif gun.name == "Sniper" then
                bulletDamage = bulletDamage * 10
                local target = nil
                local maxHealth = -math.huge
                local target = {}
                target.x = screenWidth/2
                target.y = 0
                local speedXref = (target.x) - (paddle.x + paddle.width / 2)
                local speedYref = (target.y) - (paddle.y + paddle.height / 2)
                local speedMagnitude = math.sqrt(speedXref^2 + speedYref^2)
                if speedMagnitude > 0 then
                    speedXref = (speedXref / speedMagnitude) * bulletSpeed + speedOffset
                    speedYref = (speedYref / speedMagnitude) * bulletSpeed
                else
                    speedXref = 0
                    speedYref = -bulletSpeed -- Default to straight up if no target found
                end
                local critChance = hasItem("Four Leafed Clover") and 50 or 25
                table.insert(bullets, {
                    name = gun.name,
                    type = "bullet",
                    x = paddle.x + paddle.width / 2,
                    y = paddle.y,
                    sniper = true,
                    speedX = speedXref,
                    speedY = speedYref,
                    radius = 5,
                    stats = {damage = bulletDamage * ((hasItem("Assassin's Dagger") and math.random(1,100) <= critChance) and 2 or 1)},
                    hasSplit = false,
                    hasTriggeredOnBulletHit = false,
                    golden = ((Player.currentCore == "Phantom Core" or hasItem("Phantom Bullets"))),
                })
                local chance = hasItem("Four Leafed Clover") and 20 or 10
                if math.random(1,100) <= chance and hasItem("Sudden Mitosis") then
                    local totalSpeed = 500
                    local speedX = math.random(-totalSpeed*0.6, totalSpeed*0.6)
                    local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
                    local ballTemplate = ballList["Ball"]
                    local newBall = {
                        type = "ball",
                        name = ballTemplate.name,
                        x = paddle.x + paddle.width / 2,
                        y = paddle.y - 6,
                        speedMult = ballTemplate.speedMult or 1,
                        radius = (ballTemplate.radius or 10) * 1.5,
                        drawSizeBoost = 1,
                        drawSizeMult = 0.5,
                        drawSizeBoostTweens = {},
                        onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                        currentlyOverlappingBricks = {},
                        attractionStrength = ballTemplate.attractionStrength or nil,
                        stats = ballTemplate.stats,
                        speedX = speedX,
                        speedY = speedY,
                        dead = false,
                        trail = {},
                        speedMultiplier = 1
                    }
                    table.insert(Balls, newBall)
                    Timer.after(8, function()
                        local ballDeathTween = tween.new(0.5, newBall, {drawSizeMult = 0}, tween.outCubic)
                        addTweenToUpdate(ballDeathTween)
                        Timer.after(0.5, function()
                            for i, b in ipairs(Balls) do
                                if b == newBall then
                                    table.remove(Balls, i)
                                    break
                                end
                            end 
                        end)
                    end)
                end
            else -- default shooting behavior
                local speedXref = spray and (math.random(-gun.bulletSpeed * 0.8, gun.bulletSpeed * 0.8) + speedOffset) or (math.random(-150, 150) + speedOffset)
                local xBruh = paddle.x + paddle.width / 2 + ((speedXref - speedOffset)/(spray and gun.bulletSpeed * 0.8 or 200))*50
                local critChance = hasItem("Four Leafed Clover") and 50 or 25
                table.insert(bullets, {
                    name = gun.name,
                    type = "bullet",
                    x = xBruh,
                    y = paddle.y,
                    speedX = speedXref,
                    speedY = -math.sqrt(bulletSpeed^2 - speedXref^2),
                    radius = 5,
                    stats = {damage = bulletDamage * ((hasItem("Assassin's Dagger") and math.random(1,100) <= critChance) and 2 or 1)},
                    hasSplit = false,
                    hasTriggeredOnBulletHit = false,
                    golden = (gun.name == "Golden Gun" or (Player.currentCore == "Phantom Core" or hasItem("Phantom Bullets"))),
                })
                local chance = hasItem("Four Leafed Clover") and 20 or 10
                if math.random(1,100) <= chance and hasItem("Sudden Mitosis")then
                    local totalSpeed = 500
                    local speedX = math.random(-totalSpeed*0.6, totalSpeed*0.6)
                    local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
                    local ballTemplate = ballList["Ball"]
                    local newBall = {
                        type = "ball",
                        name = ballTemplate.name,
                        x = paddle.x + paddle.width / 2,
                        y = paddle.y - 6,
                        speedMult = ballTemplate.speedMult or 1,
                        radius = (ballTemplate.radius or 10) * 1.5,
                        drawSizeBoost = 1,
                        drawSizeMult = 0.5,
                        drawSizeBoostTweens = {},
                        onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                        currentlyOverlappingBricks = {},
                        attractionStrength = ballTemplate.attractionStrength or nil,
                        stats = ballTemplate.stats,
                        speedX = speedX,
                        speedY = speedY,
                        dead = false,
                        trail = {},
                        speedMultiplier = 1
                    }
                    table.insert(Balls, newBall)
                    Timer.after(8, function()
                        local ballDeathTween = tween.new(0.5, newBall, {drawSizeMult = 0}, tween.outCubic)
                        addTweenToUpdate(ballDeathTween)
                        Timer.after(0.5, function()
                            for i, b in ipairs(Balls) do
                                if b == newBall then
                                    table.remove(Balls, i)
                                    break
                                end
                            end 
                        end)
                    end)
                end
                local normalizedSpeedX, normalizedSpeedY = normalizeVector(speedXref, -math.sqrt(bulletSpeed^2 - speedXref^2))
                muzzleFlash(xBruh, paddle.y, -math.acos(normalizedSpeedX))
            end
            if gun.name == "Minigun" then
                local sprayMult = hasItem("Four Leafed Clover") and 0.5 or 0.67
                local timeUntilNextShot = gun.fireRateMult * (mapRangeClamped(getStat("Minigun", "ammo") - gun.currentAmmo, 0, 25, 4, 0.5) * (spray and sprayMult or 1))/(getStat(gun.name, "fireRate") * bulletStormMult)
                Timer.after(timeUntilNextShot, function() shoot(gunName) end)
                -- createCooldownVFX(cooldownValue)
            else
                local sprayMult = hasItem("Four Leafed Clover") and 0.5 or 0.67
                local timeUntilNextShot = (gun.fireRateMult * 3.0 * (spray and sprayMult or 1))/(getStat(gun.name, "fireRate") * bulletStormMult)
                Timer.after(timeUntilNextShot, function() shoot(gunName) end)
                -- createCooldownVFX(cooldownValue)
            end
        else
            gun.currentAmmo = getStat(gun.name, "ammo")

            local cooldownValue = getStat(gun.name, "cooldown") * 0.5
            if accelerationOn then
                cooldownValue = cooldownValue * 0.5
            end
            Timer.after(cooldownValue, function() shoot(gunName) end)
            createCooldownVFX(cooldownValue)
        end
    else 
        print("Error: gun is not unlocked but shoot is being called.")
    end
end

local turrets = {}

local function rotateTurret(turret, right)
    if Player.dead then
        return
    end   
    if turret then
        local rotateTurretTween = tween.new(2.5, turret, {angle = (right and -math.pi * 0.25 or math.pi * 0.25)}, tween.InOutCubic)
        addTweenToUpdate(rotateTurretTween)
        Timer.after(2.5, function() 
            rotateTurret(turret, not right) 
        end)
    end
end

local fire
local turretsInQueue = 0
local lastTurretSoundTime = 0
local function turretShoot(turret)
    if Player.dead then
        return
    end   
    local turretType = unlockedBallTypes["Gun Turrets"]  
    if turret then
        if not turret.alive then
            return
        end
        if turret.currentAmmo <= 0 then
            Timer.after(2, function()
                -- Refill ammo after cooldown
                turret.currentAmmo = getStat("Gun Turrets", "ammo")
                turretShoot(turret) -- Restart shooting after ammo refill
            end)
            return
        end
        local currentTime = love.timer.getTime()
        if shootSFXCooldown <= 0 then
            playSoundEffect(gunShootSFX, 0.8, 0.8, false, true)
            shootSFXCooldown = 0.05
        end
        local bulletSpeed = turretType.bulletSpeed or 2000
        local speed = {x =math.cos((turret.angle + turret.angleOffset) - math.pi/2) * bulletSpeed, y = math.sin((turret.angle + turret.angleOffset) - math.pi/2) * bulletSpeed}
        local normalizedSpeedX, normalizedSpeedY = normalizeVector(speed.x, speed.y)
        local bulletDamage = getStat("Gun Turrets", "damage")
        if Player.currentCore == "Phantom Core" then bulletDamage = math.max(math.floor(bulletDamage /2),1) end
        local critChance = hasItem("Four Leafed Clover") and 50 or 25
        local bullet = {
            x = turret.x + normalizedSpeedX * turret.radius,
            y = turret.y + normalizedSpeedY * turret.radius * 0.8,
            speedX = speed.x,
            speedY = speed.y,
            radius = 5,
            stats = {damage = bulletDamage * ((hasItem("Assassin's Dagger") and math.random(1,100) <= critChance) and 2 or 1), type = "tech"},
            name = "Gun Turrets",
            type = "bullet",
            golden = (Player.currentCore == "Phantom Core" or hasItem("Phantom Bullets"))
        }
        table.insert(bullets, bullet)
        local chance = hasItem("Four Leafed Clover") and 20 or 10
        if math.random(1,100) <= chance and hasItem("Sudden Mitosis") then
            local totalSpeed = 500
            local speedX = math.random(-totalSpeed*0.6, totalSpeed*0.6)
            local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
            local ballTemplate = ballList["Ball"]
            local newBall = {
                type = "ball",
                name = ballTemplate.name,
                x = paddle.x + paddle.width / 2,
                y = paddle.y - 6,
                speedMult = ballTemplate.speedMult or 1,
                radius = (ballTemplate.radius or 10) * 1.5,
                drawSizeBoost = 1,
                drawSizeMult = 0.5,
                drawSizeBoostTweens = {},
                onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                currentlyOverlappingBricks = {},
                attractionStrength = ballTemplate.attractionStrength or nil,
                stats = ballTemplate.stats,
                speedX = speedX,
                speedY = speedY,
                dead = false,
                trail = {},
                speedMultiplier = 1
            }
            table.insert(Balls, newBall)
            Timer.after(8, function()
                local ballDeathTween = tween.new(0.5, newBall, {drawSizeMult = 0}, tween.outCubic)
                addTweenToUpdate(ballDeathTween)
                Timer.after(0.5, function()
                    for i, b in ipairs(Balls) do
                        if b == newBall then
                            table.remove(Balls, i)
                            break
                        end
                    end 
                end)
            end)
        end
        turret.currentAmmo = turret.currentAmmo - 1
        if turret.currentAmmo > 0 then
            Timer.after(0.5, function()
                turretShoot(turret) -- Restart shooting after ammo refill
            end)
        else
            turret.alive = false -- Mark turret as dead
            local turretDeathTween = tween.new(0.5, turret, {radius = 0}, tween.ouQuint)
            addTweenToUpdate(turretDeathTween)
            Timer.after(0.5, function()
                -- Remove turret after 10 seconds
                for i, t in ipairs(turrets) do
                    if turret.id == t.id then
                        table.remove(turrets, i)
                        break
                    end
                end
            end)
            if turretsInQueue > 0 then
                fire("Gun Turrets")
                turretsInQueue = turretsInQueue - 1
            end
        end
    end
end

local laserBeamTarget = nil
local laserBeamTimer = 0
local laserAlpha = {a = 0}
local flamethrowerStartAnim = nil
local flamethrowerLoopAnim = nil
local flamethrowerEndAnim = nil
local ammoDepletionTimer
local flamethrowerScale = 2.0
local rockets = {}
local currentTurretId = 1
fire = function(techName)
    if Player.dead then
        return
    end     
    if techName == "Atomic Bomb" then
        for _, brick in ipairs(bricks) do
            if (brick.health > 0) and (brick.y + brick.height > 0) then
                dealDamage(unlockedBallTypes["Atomic Bomb"], brick) -- Deal damage to all bricks
            end
        end
    end
    if techName == "Laser" then
        unlockedBallTypes["Laser"].currentChargeTime = 0
        playSoundEffect(laserSFX, 0.8, 1)
        laserAlpha.a = 1
        local laserTween = tween.new(0.35, laserAlpha, {a = 0}, tween.inQuad)
        addTweenToUpdate(laserTween)
        for _, brick in ipairs(bricks) do
            if not brick.destroyed and brick.y > -brick.height then
                if paddle.x < brick.x + brick.width and paddle.x + paddle.width > brick.x then
                    dealDamage(unlockedBallTypes["Laser"], brick)
                end
            end
        end
        unlockedBallTypes["Laser"].charging = true
    end
    if techName == "Rocket Launcher" then
        if unlockedBallTypes["Rocket Launcher"].currentAmmo > 0 then
            local angle = hasItem("Spray and Pray") and 0 + math.random(-40, 40) or 0 + math.random(-7, 7)
            local speed = 800
            local rocket = {
                x = paddle.x + paddle.width / 2,
                y = paddle.y - paddle.height,
                speedX = speed * math.sin(math.rad(angle)),
                speedY = -speed * math.cos(math.rad(angle)),
                angle = angle,  -- In degrees
                radius = 40,
                damage = unlockedBallTypes["Rocket Launcher"].stats.damage,
                animation = getAnimation(createSpriteAnimation(paddle.x + paddle.width / 2, paddle.y - paddle.height, 0, rocketVFX, 16, 69, 0.05, 0, true, 1.75, 1.75, angle))
            }

            local newRocketTween = tween.new(0.1, rocket.animation, {scale = 1}, tween.outCubic)
            addTweenToUpdate(newRocketTween)
            
            -- Add the rocket to the rockets table
            table.insert(rockets, rocket)

            unlockedBallTypes["Rocket Launcher"].currentAmmo = unlockedBallTypes["Rocket Launcher"].currentAmmo - 1
            -- Reset ammo and set cooldown
            if unlockedBallTypes["Rocket Launcher"].currentAmmo <= 0 then
                local cooldownValue = getStat("Rocket Launcher", "cooldown") * 0.8
                if accelerationOn then
                    cooldownValue = cooldownValue * 0.5
                end
                Timer.after(math.max(cooldownValue, 6/getStat("Rocket Launcher", "fireRate")), function()
                    unlockedBallTypes["Rocket Launcher"].currentAmmo = getStat("Rocket Launcher", "ammo")
                    fire("Rocket Launcher")
                end)
                createCooldownVFX(cooldownValue)
            else
                local timerLength = (Player.currentCore == "Madness Core" and 0.5 or 1) * 6/getStat("Rocket Launcher", "fireRate")
                if hasItem("Spray and Pray") then
                    local timerMult = hasItem("Four Leafed Clover") and 0.5 or 0.67
                    timerLength = timerLength * timerMult
                end
                Timer.after(timerLength, function()
                    fire("Rocket Launcher")
                end)
            end
        end
    end
    if techName == "Flamethrower" then
        local flamethrower = unlockedBallTypes["Flamethrower"]
        -- Only start if not already shooting
        if not flamethrower.shooting then
            -- Use FlamethrowerVFX system
            if not flamethrower.vfx then
                local FlamethrowerVFX = require("particleSystems.FlamethrowerVFX")
                flamethrower.vfx = FlamethrowerVFX:new(paddle.x + paddle.width / 2, paddle.y, -math.pi/2)
            end
            flamethrower.vfx:setPosition(paddle.x + paddle.width / 2, paddle.y)
            flamethrower.vfx:setDirection(-math.pi/2) -- Point up
            flamethrower.vfx:start()
            flamethrower.shooting = true
            -- Start ammo depletion timer
            ammoDepletionTimer = Timer.every(0.4, function()
                flamethrower.currentAmmo = flamethrower.currentAmmo - 1
                if flamethrower.currentAmmo <= 0 then
                    flamethrower.vfx:stop()
                    flamethrower.shooting = false
                    Timer.cancel(ammoDepletionTimer)
                    -- Refill ammo after cooldown
                    local cooldownValue = getStat("Flamethrower", "cooldown") * 0.8
                    if accelerationOn then
                        cooldownValue = cooldownValue * 0.5
                    end
                    Timer.after(cooldownValue * 0.6, function()
                        flamethrower.currentAmmo = getStat("Flamethrower", "ammo")
                        fire("Flamethrower")
                    end)
                    createCooldownVFX(cooldownValue)
                end
            end)
        end
    end
    if techName == "Gun Turrets" then
        -- handles the entire logic for spawning, placing and after 10 seconds, destroying a turret. also handles first shot
        if #turrets < 50 then
            local turretType = unlockedBallTypes["Gun Turrets"]
            local id = currentTurretId
            local destination = {x = (math.random(50, screenWidth - 50)), y = math.random(math.max(paddle.y + 50, screenHeight - 300), screenHeight - 25)}
            local startDir = math.random(0,1)
            local turret = {
                id = currentTurretId,
                x = paddle.x + paddle.width / 2,
                y = paddle.y + paddle.height/2, -- Position above the paddle
                radius = 0,
                currentAmmo = getStat("Gun Turrets", "ammo"),
                angle = (startDir == 1 and math.pi*0.25 or -math.pi*0.25),
                angleOffset = math.random(-100, 100)/100 * math.pi * 0.2,
                stats = turretType.stats,
                alive = true,
            }
            currentTurretId = currentTurretId + 1
            local lookDirectionX, lookDirectionY = normalizeVector(screenWidth/2 - destination.x, - destination.y)
            local directionAngle = 0
            local turretPositionTween = tween.new(0.5, turret, {x = destination.x, y = destination.y, angle = turret.angle, radius = 65}, tween.outCubic)
            addTweenToUpdate(turretPositionTween)
            table.insert(turrets, turret)
            -- first shot when turret in position
            Timer.after(0.5, function() 
                rotateTurret(turret, startDir == 1)
            end)
            Timer.after(1 + math.random(0, 100) / 100, function()
                turretShoot(turret)
            end)
            local cooldownValue = 1.5 + getStat("Gun Turrets", "cooldown") * 0.4
            if accelerationOn then
                cooldownValue = cooldownValue * 0.5
            end
            Timer.after(cooldownValue, function()
                -- Refill ammo after cooldown
                turret.currentAmmo = getStat("Gun Turrets", "ammo")
                fire("Gun Turrets")
            end)
            createCooldownVFX(cooldownValue)
        else
            turretsInQueue = turretsInQueue + 1
        end
    end
end

-- Table to hold active arcane missiles
local arcaneMissiles = {}

function getArcaneMissileCount()
    return #arcaneMissiles
end

local function castArcaneMissile(ball)
    -- Per-ball cooldown: only allow cast once per 2 seconds per ball
    local redo = true
    local targetBrick = nil
    while redo do
        local brick = bricks[math.random(1, #bricks)]
        if (not brick.destroyed) and brick.health > 0 and brick.y > -brick.height then
            targetBrick = brick
            redo = false
        end
    end
    local angle = (math.random() * 0.5 - 0.75) * math.pi
    local missileSpeed = 2000
    local startX = paddle.x + paddle.width/2
    local startY = paddle.y
    local vx = math.cos(angle) * missileSpeed
    local vy = math.sin(angle) * missileSpeed
    table.insert(arcaneMissiles, {
        name = "Arcane Missiles",
        x = startX,
        y = startY,
        vx = vx,
        vy = vy,
        radius = 8,
        damage = getStat(ball.name, "damage"),
        alive = true,
        target = targetBrick
    })
end

local shadowBalls = {}
local fireballs = {}
local lightBeams = {}
function getShadowBallCount()
    return #shadowBalls
end
function getFireballCount()
    return #fireballs
end
function getLightBeamCount()
    return #lightBeams
end

local lastFireballsCastTime = 0
local lightningSFXCooldown = 0
local lightBeamOpacity = {a = 0}
local lightBeamAngle = 0
local shadowballId = 0
local lightBeamId = 0
local function cast(spellName, brick, forcedDamage)
    if Player.dead then
        return
    end   
    if spellName == "Shadow Ball" then
        local angle = hasItem("Spray and Pray") and (math.random() * 0.5 + 0.25) * math.pi or (math.random() * 0.2 + 0.4) * math.pi
        local speed = 350
        local range = 1.5 + getStat("Shadow Ball", "range") * 0.5
        local shadowBall = {
            id = shadowballId,
            name = "Shadow Ball",
            x = paddle.x + paddle.width / 2 + paddle.width * ((angle/math.pi)-0.5)* -0.5,
            y = paddle.y,
            speedX = speed * math.cos(angle),
            speedY = -speed * math.sin(angle),
            radius = 0,
            stats = unlockedBallTypes["Shadow Ball"].stats,
            damage = getStat("Shadow Ball", "damage"),
            range = range,
            trail = {},
            dead = false
        }
        shadowballId = shadowballId + 1
        -- Removed shadowBall hit sound effect
        table.insert(shadowBalls, shadowBall)
        local shadowBallStartTween = tween.new(0.25, shadowBalls[#shadowBalls], {radius = 5 * range}, tween.outExpo)
        addTweenToUpdate(shadowBallStartTween)
        local sprayCooldown = hasItem("Four Leafed Clover") and 10 or 13.34 -- this is correct, stop tweaking and changing it
        local cooldownLength = hasItem("Spray and Pray") and sprayCooldown/(getStat("Shadow Ball", "fireRate") + 2) or 20/(getStat("Shadow Ball", "fireRate"))
        Timer.after(cooldownLength, function()
            -- Refill shadowBall spell after cooldown
            cast("Shadow Ball")
        end)
    end
    if spellName == "Fireballs" then
        print("Casting Fireballs")
        lastFireballsCastTime = gameTime
        for i=1, getStat("Fireballs", "amount") do
            local angle = (math.random() * 0.5 + 0.25) * math.pi
            local speed = 600
            local xTo = paddle.x + paddle.width / 2 + paddle.width * ((angle/math.pi)-0.5)* -0.5
            local fireball = {
                x = xTo,
                y = paddle.y,
                speedX = speed * math.cos(angle),
                speedY = -speed * math.sin(angle),
                radius = 0,
                stats = unlockedBallTypes["Fireballs"].stats,
                damage = getStat("Fireballs", "damage"),
                trail = {},
                dead = false,
                animation = getAnimation(createSpriteAnimation(xTo, paddle.y, 0, fireballVFX, 64, 64, 0.05, 0, true, 1, 1, -angle*360/2/math.pi, {1,1,1,1}, false, nil, 8))
            }
            table.insert(fireballs, fireball)
            local fireballStartTween = tween.new(0.25, fireball.animation, {scale = 1.5}, tween.outExpo)
            addTweenToUpdate(fireballStartTween)
        end
        local cooldownValue = 12 / getStat("Fireballs", "fireRate")
        local timeUntilNextCast = (3 + cooldownValue)/3
        Timer.after(timeUntilNextCast, function()
            cast("Fireballs")
        end)
        createCooldownVFX(cooldownValue)
    end
    if spellName == "Light Beam" then        
        local ammoValue = getStat("Light Beam", "ammo")
        for i=1, ammoValue do
            Timer.after((i-1) * 0.2 + 0.05, function()
                playSoundEffect(lightBeamSFX, 0.2, 0.6)
            end)
            Timer.after(i * 0.2, function()
                local angle = math.pi + math.random(-10, 10)/100 * math.pi
                local lightBeam = {
                    id = lightBeamId,
                    angle = angle,
                    opacity = 0,
                    bricksCD = {},
                }
                lightBeamId = lightBeamId + 1
                table.insert(lightBeams, lightBeam)
                local tweenStart = tween.new(0.05, lightBeam, {opacity = 1}, tween.outExpo)
                addTweenToUpdate(tweenStart)
                Timer.after(0.05, function()
                    local bricksInHitbox = getBricksInRectangle(paddle.x + paddle.width/2 - 0, paddle.y, 60, 5000000000, lightBeam.angle)
                    for _, brick in ipairs(bricksInHitbox) do
                        if brick.y > -brick.height then
                            dealDamage(unlockedBallTypes["Light Beam"], brick)
                        end
                    end
                    local tweenEnd = tween.new(0.15, lightBeam, {opacity = 0}, tween.outExpo)
                    addTweenToUpdate(tweenEnd)
                    Timer.after(0.15, function()
                        for i, lb in ipairs(lightBeams) do
                            if lb.id == lightBeam.id then
                                table.remove(lightBeams, i)
                                break
                            end
                        end
                    end)
                end)
            end)        end
        local cooldownValue = getStat("Light Beam", "cooldown") * 1.5
        if accelerationOn then
            cooldownValue = cooldownValue * 0.5
        end
        Timer.after(0.2 * ammoValue + math.max(cooldownValue, 0) + 0.05, function()
            cast("Light Beam")
        end)
        createCooldownVFX(cooldownValue)
    end
    if spellName == "Lightning Pulse" then
        print("Casting Lightning Pulse")
        for i=1, getStat("Lightning Pulse", "amount") do
            Timer.after(i * 0.035, function()
                playSoundEffect(lightningPulseSFX, 0.1, 0.85)
                local selectedBrickIds = {}
                local iterations = 0
                local go = true
                local randomBrick
                while go do
                    iterations = iterations + 1
                    local randomBrickId = math.random(1, #bricks)
                    randomBrick = bricks[randomBrickId]
                    if randomBrick.y >= 0 and randomBrick.health > 0 and (not randomBrick.destroyed) then
                        go = false
                        for _, Id in ipairs(selectedBrickIds) do
                            if randomBrickId == Id then
                                go = true
                            else
                                table.insert(selectedBrickIds, randomBrickId)
                            end
                        end
                    elseif iterations >= 100 then
                        go = false
                    end
                end
                createSpriteAnimation(randomBrick.x + randomBrick.width/2, randomBrick.y + randomBrick.height/2, 0.25, sparkVFX, 512, 512, 0.075, 1)
                Timer.after(0.125, function()
                    dealDamage(unlockedBallTypes["Lightning Pulse"], randomBrick)
                end)
            end)
        end
        local cooldownValue = getStat("Lightning Pulse", "cooldown")
        if accelerationOn then
            cooldownValue = cooldownValue * 0.5
        end
        local timeUntilNextCast = (1 + math.max(cooldownValue, 0))/5
        Timer.after(timeUntilNextCast, function()
            cast("Lightning Pulse")
        end)
        createCooldownVFX(timeUntilNextCast)
    end
    if spellName == "Chain Lightning" or spellName == "Lightning Ball" or spellName == "Incrediball" then
        local ballType = unlockedBallTypes[spellName]
        
        -- Skip if brick is on cooldown
        if brick and lightningCooldowns[brick.id] and (love.timer.getTime() - lightningCooldowns[brick.id]) < 0.2 then
            return
        end
        
        -- Set cooldown for this brick
        if brick then
            lightningCooldowns[brick.id] = love.timer.getTime()
        end
        
        local chainLength = 1
        if spellName == "Chain Lightning" then
            chainLength = 3
        else
            chainLength = getStat(ballType.name, "range")
        end
        local function chainStep(currentBrick, step)
            if step > chainLength or not currentBrick then return end
            
            -- Skip bricks on cooldown
            if lightningCooldowns[currentBrick] and (love.timer.getTime() - lightningCooldowns[currentBrick]) < 0.2 then
                print("Chain target brick on cooldown, skipping")
                return
            end
            
            -- Set cooldown for chain target
            lightningCooldowns[currentBrick] = love.timer.getTime()
            
            local currentX, currentY = currentBrick.x, currentBrick.y
            local touchingBricks = getBricksInCircle(currentX, currentY, 100)
            -- Filter out valid targets
            local validTargets = {}
            for _, b in ipairs(touchingBricks) do
                if b ~= currentBrick and not b.destroyed and b.health > 0 and b.y > -brick.height then
                    table.insert(validTargets, b)
                end
            end
            if #validTargets > 0 then
                -- Find the nearest brick in validTargets
                local minDist = math.huge
                local targetBrick = nil
                for _, b in ipairs(validTargets) do
                    local dx = b.x - currentBrick.x
                    local dy = b.y - currentBrick.y
                    local dist = dx*dx + dy*dy
                    if dist < minDist then
                        minDist = dist
                        targetBrick = b
                    end
                end
                if targetBrick then
                    local scaleX = math.sqrt((targetBrick.x - currentBrick.x)^2 + (targetBrick.y - currentBrick.y)^2)/256
                    local angle = math.atan2(targetBrick.y - currentBrick.y, targetBrick.x - currentBrick.x) * 180 / math.pi
                    local spawnX = ((currentBrick.x + currentBrick.width / 2) + (targetBrick.x + targetBrick.width / 2)) / 2
                    local spawnY = ((currentBrick.y + currentBrick.height / 2) + (targetBrick.y + targetBrick.height / 2)) / 2
                    local distance = math.sqrt((targetBrick.x - currentBrick.x)^2 + (targetBrick.y - currentBrick.y)^2)
                    if lightningSFXCooldown <= 0 then
                        playSoundEffect(lightningSFX, 0.3, 0.75)
                        lightningSFXCooldown = 0.05
                    end
                    createSpriteAnimation(spawnX, spawnY, mapRangeClamped(distance, 0, 350, 2.0, 1.0), chainLightningVFX, 256, 128, 0.075, 0, false, scaleX, scaleX*1.5, angle)
                    Timer.after(0.3, function()
                        if forcedDamage then
                            dealDamage({stats = {damage = forcedDamage}}, targetBrick)
                        else
                            dealDamage(ballType, targetBrick)
                        end
                        chainStep(targetBrick, step + 1)
                    end)
                end
            else
                print("Chain Lightning on brick is on cooldown.")
            end
        end
        chainStep(brick, 1)
    end
end

local gravityWell = {
    name = "Gravity pulse",
    type = "tech",
    size = 1,
    noAmount = true,
    rarity = "rare",
    startingPrice = 50,
    description = "Creates an attraction point at nearest brick that pulls balls and bullets towards it.",
    color = {0.1, 0.1, 0.3, 1},
    stats = {
        range = 7,
        speed = 200
    },
    attractionStrength = 175,
    techTarget = nil,
    animTime = 0
}

--list of all ball types in the game
local function ballListInit()
    ballList = {
        ["Ball"] = {
            name = "Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            speedMult = 2,
            size = 1,
            rarity = "common",
            ballAmount = 1,
            startingPrice = 5,
            description = "Basic ball. Very fast.",
            color = {1, 1, 1, 1}, -- White color
            stats = {
                speed = 150,
                damage = 1,
            },
            canBuy = function() return false end,
        },
        --[[["Sword"] = {
            name = "Sword",
            type = "tech",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "common",
            startingPrice = 5,
            description = "Strikes in front of the paddle, dealing damage in an area",
            color = {1, 1, 1, 1}, -- White color
            stats = {
                speed = 150,
                damage = 1,
                range = 2
            },
        },]]
        ["Exploding Ball"] = {
            name = "Exploding Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            ballAmount = 1,
            speedMult = 1,
            size = 1,
            rarity = "rare",
            startingPrice = 50,
            description = "A ball that explodes on impact, dealing damage to nearby bricks.",
            color = {1, 0, 0, 1}, -- Red color
            stats = {
                speed = 100,
                damage = 1,
                range = 3
            },
        },
        ["Phantom Ball"] = {
            name = "Phantom Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            ballAmount = 1,
            speedMult = 0.3,
            size = 2,
            rarity = "rare",
            startingPrice = 100,
            description = "A ball that can pass through bricks.",
            color = {0.5, 0.5, 0.7, 0.6}, -- Blue color
            stats = {
                speed = 150,
                damage = 1,
                range = 3
            },
        },
        ["Magnetic Ball"] = {
            name = "Magnetic Ball",
            type = "ball",
            ballAmount = 1,
            x = screenWidth / 2,
            y = screenHeight / 2,
            speedMult = 1.25,
            size = 1,
            rarity = "common",
            startingPrice = 25,
            description = "A ball that's magnetically attracted to the nearest brick",
            color = {0.6, 0.2, 0.8, 1}, -- Purple color
            stats = {
                speed = 150,
                damage = 1,
            },
            attractionStrength = 500
        },
        ["Lightning Ball"] = {
            name = "Lightning Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            speedMult = 1,
            size = 1,
            ballAmount = 1,
            rarity = "uncommon",
            startingPrice = 50,
            description = "Creates a damaging electric current between bricks on hit.",
            color = {0, 170/255, 1, 1}, -- green color
            stats = {
                speed = 150,
                damage = 1,
                range = 1
            },
        },
        ["Gun Ball"] = {
            name = "Gun Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            speedMult = 1,
            size = 1,
            rarity = "common",
            startingPrice = 50,
            ballAmount = 1,
            description = "A ball that shoots bullets in a random direction like a gun on bounce.",
            color = {0.8, 0.4, 0.1, 1}, -- Orange color
            bulletSpeed = 1000,
            currentAmmo = 1,
            onBounce = function(ball)
                shoot("Gun Ball", ball)
            end,
            stats = {
                speed = 100,
                damage = 1,
            },
        },
        ["Incrediball"] = {
            name = "Incrediball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            speedMult = 1.25,
            noAmount = true,
            size = 1,
            rarity = "legendary",
            startingPrice = 50,
            ballAmount = 1,
            description = "Has the effects of every other ball (except phantom ball).",
            color = {0.5, 0.5, 0.5, 1}, -- Orange color
            bulletSpeed = 1000,
            currentAmmo = 1,
            onBounce = function(ball)
                shoot("Incrediball", ball)
            end,
            stats = {
                speed = 100,
                damage = 1,
                range = 2,
            },
            canBuy = function() return hasItem("Superhero t-shirt") end,
            attractionStrength = 2000
        },
        ["Machine Gun"] = {
            name = "Machine Gun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "common",
            startingPrice = 10,
            ammoMult = 5,
            fireRateMult = 0.325,
            description = "Fires bullets, fast fireRate",
            onBuy = function() 
                shoot("Machine Gun")
            end,
            noAmount = true,
            currentAmmo = 8 + ((Player.permanentUpgrades.ammo or 0)) * 5,
            bulletSpeed = 1000,
            canBuy = function() return false end,

            stats = {
                damage = 1,
                cooldown = 8,
                ammo = 14,
                fireRate = 3,
            },
        },
        Shotgun = {
            name = "Shotgun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "common",
            ammoMult = 2,
            fireRateMult = 1.8,
            startingPrice = 25,
            description = "Fire bullets that die on impact in bursts.",
            onBuy = function() 
                shoot("Shotgun")
            end,
            noAmount = true,
            currentAmmo = 2 + ((Player.permanentUpgrades.ammo or 0)) * 2,
            bulletSpeed = 1500,

            stats = {
                damage = 1,
                cooldown = 10,
                ammo = 2,
                fireRate = 1,
            },
        },
        ["Ball Gun"] = {
            name = "Ball Gun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            radius = 10,
            rarity = "uncommon",
            speedMult = 2,
            ammoMult = 3,
            fireRateMult = 6,
            startingPrice = 50,
            description = "A gun that shoots balls. \nDoesn't need to reload. \nSlow fire rate.",
            onBuy = function() 
                shoot("Ball Gun")
            end,
            noAmount = true,
            currentAmmo = 3 + ((Player.permanentUpgrades.ammo or 0)) * 3,
            bulletSpeed = 1250,
            stats = {
                damage = 1,
                amount = 1,
                fireRate = 2,
                speed = 150
            },
        },
        Minigun = {
            name = "Minigun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 50,
            ammoMult = 20,
            fireRateMult = 1.2,
            description = "Fires bullets at an accelerating rate of fire. very long cooldown",
            onBuy = function() 
                shoot("Minigun")
            end,
            noAmount = true,
            currentAmmo = 100 + ((Player.permanentUpgrades.ammo or 0)) * 20,
            bulletSpeed = 1000,
            stats = {
                damage = 2,
                cooldown = 12,
                ammo = 100,
                fireRate = 6,
            },
        },
        ["Golden Gun"] = {
            name = "Golden Gun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            ammoMult = 2,
            fireRateMult = 1.35,
            rarity = "rare",
            startingPrice = 100,
            description = "Fires golden bullets that pass through all bricks and always deal full damage.",
            onBuy = function()
                shoot("Golden Gun")
            end,
            noAmount = true,
            currentAmmo = 2 + ((Player.permanentUpgrades.ammo or 0)) * 2,
            bulletSpeed = 1500,
            stats = {
                damage = 1,
                cooldown = 10,
                ammo = 2,
                fireRate = 1,
            },
            canBuy = function()
                return Player.currentCore ~= "Phantom Core"
            end,
        },
        Laser = {
            name = "Laser",
            type = "tech",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            charging = true,
            currentChargeTime = 0,
            noAmount = true,
            rarity = "uncommon",
            startingPrice = 100,
            description = "Paddle shoots Laser with that hits every brick in front of it. \nLong Cooldown" .. 
            "\n Very long cooldown",
            color = {0, 1, 0, 1}, -- Green color
            stats = {
                damage = 3,
                cooldown = 14,
            },
        },
        ["Laser Beam"] = {
            name = "Laser Beam",
            type = "tech",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "common",
            startingPrice = 25,
            description = "Fire a thin Laser Beam beam in front of the paddle.",
            color = {1, 0, 0, 1}, -- Red color for Laser Beam
            stats = {
                damage = 1,
                fireRate = 2,
            },
            angle = 0
        },
        ["Flamethrower"] = {
            name = "Flamethrower",
            type = "tech",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            ammoMult = 3,
            rarity = "uncommon",
            startingPrice = 25,
            description = "A flamethrower that shoots fire at a fast rate. Can burn bricks dealing damage over time.",
            color = {1, 0.5, 0, 1}, -- Orange color for Flamethrower
            currentAmmo = 3 + ((Player.permanentUpgrades.ammo or 0)) * 3,
            shooting = false,
            onBuy = function()
                fire("Flamethrower")
            end,
            stats = {
                damage = 1,
                ammo = 6,
                cooldown = 12,
            },
            canBuy = function() return Player.currentCore ~= "Damage Core" end
        },
        ["Rocket Launcher"] = {
            name = "Rocket Launcher",
            type = "tech",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "common", 
            startingPrice = 25,
            ammoMult = 2,
            description = "Shoots rockets that explode on impact.",
            color = {0.8, 0.2, 0.2, 1}, -- Dark red color
            currentAmmo = 2 + ((Player.permanentUpgrades.ammo or 0)) * 2,
            onBuy = function()
                fire("Rocket Launcher")  
            end,
            stats = {
                damage = 2,
                ammo = 4,
                cooldown = 11,
                fireRate = 1,
                range = 3
            }
        },
        --[[["Saw Blades"] = {
            name = "Saw Blades",
            type = "tech",
            size = 1,
            noAmount = true,
            rarity = "uncommon",
            startingPrice = 100,
            description = "Creates deadly Saw Blades that orbit around your paddle, damaging any bricks they touch",
            color = {0.7, 0.7, 0.7, 1}, -- Grey color theme
            stats = {
                damage = 1,
                amount = 1, -- Number of saws
                speed = 50, -- Rotations per second
            },
            sawPositions = {}, -- Will store current positions of saws
            sawAnimations = {}, -- Will store animation IDs
            currentAngle = 0, -- Current rotation angle
            orbitRadius = 225,
            damageCooldowns = {}, -- Add this line to track cooldowns per saw per brick
        },]]
        ["Gun Turrets"] = {
            name = "Gun Turrets",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            ammoMult = 3,
            rarity = "uncommon",
            startingPrice = 50,
            description = "Generates turrets that shoots bricks. \n(max 20)",
            bulletSpeed = 1500,
            color = {0.5, 0.5, 0.5, 1}, -- Grey color for Turret Generator
            currentAmmo = 6 + ((Player.permanentUpgrades.ammo or 0)) * 3,
            onBuy = function() 
                fire("Gun Turrets")
            end,
            canBuy = function()
                return Player.currentCore ~= "Damage Core"
            end,
            stats = {
                ammo = 9,
                cooldown = 10,
                damage = 1,
            },
        },
        ["Shadow Ball"] = {
            name = "Shadow Ball",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "uncommon",
            startingPrice = 25,
            description = "shoots shadowBalls that pass through bricks. Very slow fire rate.",
            color = {1, 0.5, 0, 1}, -- Orange color for shadowBall
            counter = 0,
            onBuy = function()
                Timer.after(0.15, function()
                    cast("Shadow Ball")
                end)
            end,
            stats = {
                damage = 1,
                range = 2,
                fireRate = 1,
            }
        },
        ["Fireballs"] = {
            name = "Fireballs",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "rare",
            startingPrice = 100,
            description = "shoot fireballs that explodes on impact, dealing area damage.",
            color = {1, 0.3, 0, 1}, -- Orange color for Fireball
            onBuy = function()
                cast("Fireballs")
            end,

            stats = {
                amount = 1,
                damage = 1,
                fireRate = 1,
                range = 2
            },
        },
        ["Light Beam"] = {
            name = "Light Beam",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "rare",
            startingPrice = 100,
            description = "Fires beams of light that pierces through bricks, dealing huge aoe damage.",
            color = {1, 1, 0.5, 1}, -- Yellow color for Light Beam
            stats = {
                damage = 2,
                ammo = 2,
                cooldown = 12
            },
            onBuy = function()
                cast("Light Beam")
            end,
        },
        ["Lightning Pulse"] = {
            name = "Lightning Pulse",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "uncommon",
            startingPrice = 50,
            description = "every [cooldown] seconds, pulses of lightning appear at random positions on the screen, dealing damage.",
            color = {0.8, 0.8, 0.2, 1},
            onBuy = function()
                cast("Lightning Pulse")
            end,
            stats = {
                cooldown = 9,
                damage = 2,
                amount = 2, -- Amount of Lightning Pulses
            },
        },
        ["Gun Ball Gun"] = {
            name = "Gun Ball Gun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            fireRateMult = 3,
            rarity = "legendary",
            startingPrice = 500,
            description = "A powerful gun that shoots Gun Balls. \nDoesn't need to reload. \nSlow fire rate.",
            color = {0.8, 0.4, 0.1, 1},
            stats = {
                damage = 1,
                amount = 1,
                fireRate = 2,
                speed = 200
            },
            onBounce = function(ball)
                shoot("Gun Ball Gun", ball)
            end,
            canBuy = function()
                local hasBallGun = false
                local hasGunBall = false
                for _, ballType in pairs(unlockedBallTypes) do
                    if ballType.name == "Ball Gun" then
                        hasBallGun = true
                    elseif ballType.name == "Gun Ball" then
                        hasGunBall = true
                    end
                end
                return hasBallGun and hasGunBall and #unlockedBallTypes >= 4
            end,
            onBuy = function()
                shoot("Gun Ball Gun")
            end,
        }

    }
    for _, ball in pairs(ballList) do
        ball.radius = ball.size*10 -- Set the radius based on size
    end
    print("Ball list initialized with " .. #ballList .. " ball types.")
end

commonWeapons = {}
uncommonWeapons = {}
rareWeapons = {}
legendaryWeapons = {}
local function organiseBallList()
    for _, ballType in pairs(ballList) do
        if ballType.rarity == "common" and ballType.name ~= "ball" then
            table.insert(commonWeapons, ballType)
        elseif ballType.rarity == "uncommon" then
            table.insert(uncommonWeapons, ballType)
        elseif ballType.rarity == "rare" then
            table.insert(rareWeapons, ballType)
        elseif ballType.rarity == "legendary" then
            table.insert(legendaryWeapons, ballType)
        end
    end
end

local commonWeapons = {}
local uncommonWeapons = {}
local addBallsQueued = false

-- calls ballListInit and adds a ball to it
function Balls.initialize()
    fastBricksReset()
    Player.setMoney(0);
    -- initializeRarityItemLists()
    longTermInvestment.value = 0
    Player.items = {}
    Player.levelingUp = false
    Player.choosingUpgrade = false
    Player.upgradePriceMultScaling = 2
    Player.xpForNextLevel = 15
    Player.xpGainMult = 1
    Player.setMoney(0);
    if Player.currentCore == "Loan Core" then
        Player.setMoney(20)
    end
    Player.permanentUpgrades = {}
    inGame = true
    deathTimerOver = false
    deathTweenValues = {speed = 1, overlayOpacity = 0}
    Player.level = 1
    ballCategories = {}
    ballList = {}   
    unlockedBallTypes = {}
    Player.xp = 0
    nextBallPrice = 100
    ballListInit()
    if Player.currentCore == "Speed Core" then
        speedCoreInitialize()
    end
    rockets = {}
    turrets = {}
    shadowBalls = {}
    bullets = {}
    arcaneMissiles = {}
    darts = {}
    Player.newStatLevelRequirement = 10
    Player.newWeaponLevelRequirement = 5
    uiOffset.x = usingMoneySystem and 0 or statsWidth * 1.5
    organiseBallList()
    resetGoldBricksValues()
    permanentItemBonuses = {}
    resetXpStuff()

    -- sets which items should be visible
    Items.setAllVisible(true)
    if Player.coreRestrictions[Player.currentCore] then
        print("lets do the restricitions!")
        for _, itemName in pairs(Player.coreRestrictions[Player.currentCore] or {}) do
            print("Making item invisible: " .. itemName)
            Items.addInvisibleItem(itemName)
        end
    end
end

function Balls.amountDecrease(decreaseValue)
    local ballTypeAmountToRemove = {}
    for _, ballType in pairs(unlockedBallTypes) do
        if ballType.type == "ball" and ballType.name ~= "Incrediball" then
            ballTypeAmountToRemove[ballType.name] = math.min(decreaseValue, ballType.amount)
        end
    end
    for i = #Balls, 1, -1 do
        local ball = Balls[i]
        if ball.type == "ball" then
            if ballTypeAmountToRemove[ball.name] then
                if ballTypeAmountToRemove[ball.name] > 0 then
                    ballTypeAmountToRemove[ball.name] = ballTypeAmountToRemove[ball.name] - 1
                    table.remove(Balls, i)
                    if ballTypeAmountToRemove[ball.name] <= 0 then
                        ballTypeAmountToRemove[ball.name] = nil
                    end
                end
            else
                print("wtf, there's no entry for " .. ball.name .. " in ballTypeAmountToRemove")
            end
        end
    end
    if ballTypeAmountToRemove ~= {} then
        for ballTypeName, amountLeft in pairs(ballTypeAmountToRemove) do
            print("not enough balls of type " .. ballTypeName .. " to remove the requested amount. " .. amountLeft .. " more needed.")
        end
    end
end

function Balls.amountIncrease(increaseValue)
    local increaseValue = increaseValue or 1
    for _, ballType in pairs(unlockedBallTypes) do
        if ballType.type == "ball" and ballType.name ~= "Incrediball" then
            if increaseValue > 0 then
                print("increaseValue for " .. ballType.name .. " = " .. increaseValue)
                for i = 1, increaseValue do
                    Balls.addBall(ballType.name, true)
                end
            end
        end
    end
end


function Balls.clear()
    ballCategories = {}
    ballList = {}   
    unlockedBallTypes = {}
    ballListInit()
    rockets = {}
    turrets = {}
    shadowBalls = {}
    bullets = {}
    arcaneMissiles = {}
    darts = {}
end

statDoubled = nil
accelerationOn = false
function getStat(ballTypeName, statName)
    if unlockedBallTypes[ballTypeName] then
        local baseValue = unlockedBallTypes[ballTypeName].stats[statName] or 0
        local bonusValue = getStatItemsBonus(statName, ballList[ballTypeName]) + (Player.permanentUpgrades[statName] or 0)
        local totalValue
        if statName == "ammo" then
            totalValue = baseValue + bonusValue * (unlockedBallTypes[ballTypeName].ammoMult or 1)
            print("Calculating ammo for " .. ballTypeName .. ": baseValue = " .. baseValue .. ", bonusValue = " .. bonusValue .. ", ammoMult = " .. (unlockedBallTypes[ballTypeName].ammoMult or 1) .. ", totalValue = " .. totalValue)
        elseif statName == "speed" then
            totalValue = baseValue + bonusValue * 50
        else
            totalValue = baseValue + bonusValue
        end
        if statDoubled == statName then
            totalValue = totalValue * 2
        elseif accelerationOn and (statName == "fireRate" or statName == "speed") then
            totalValue = totalValue * 2
        end
        if statName == "cooldown" then
            totalValue = math.max(0, totalValue)
        else
            totalValue = math.max(1, totalValue)
        end
        return totalValue
    else return 0 end
end

function Balls.addBall(ballName, singleBall)
    singleBall = singleBall or false -- If singleBall is not provided, default to false
    ballName = ballName or "Ball" -- Default to baseBall if no name is provided
    if type(ballName) ~= "string" then
        ballName = "Ball"
    end
    print("Adding ball: " .. ballName)

    -- Check if ball type is already unlocked
    local isNewBall = not unlockedBallTypes[ballName]

    local stats = nil
    local ballTemplate = ballList[ballName]
    if ballTemplate then -- makes sure there is a ball with ballName in ballList
        print("isNewBall: " .. tostring(isNewBall))
        local upgradePrice
        if ballTemplate.rarity == "common" then
            upgradePrice = 2
        elseif ballTemplate.rarity == "uncommon" then
            upgradePrice = 4
        elseif ballTemplate.rarity == "rare" then
            upgradePrice = 6
        elseif ballTemplate.rarity == "legendary" then
            upgradePrice = 8
        else
            upgradePrice = 3
        end
        if Player.currentCore == "Hacker Core" then
            upgradePrice = 0
        end
        if isNewBall then
            local newBallType = {
                name = ballName, -- Set the name of the ball
                type = ballTemplate.type,
                amount = 1, -- Set the initial amount to 1
                noAmount = ballTemplate.noAmount or false, -- Set noAmount to false if not specified
                charging = true,
                cooldownTimer == nil,
                currentChargeTime = 0,
                speedMult = ballTemplate.speedMult or 1, -- Set the speed multiplier if it exists
                fireRateMult = ballTemplate.fireRateMult or 1,
                rarity = ballTemplate.rarity or "common",
                color = ballTemplate.color or {1, 1, 1, 1}, -- Set the color of the ball
                price = upgradePrice, -- Set the initial price of ball upgrades
                ballAmount = ballTemplate.ballAmount or 0,
                currentAmmo = (ballTemplate.currentAmmo or 0), -- Copy specific values from the template
                bulletSpeed = ballTemplate.bulletSpeed or 1000, -- Set the bullet speed if it exists
                attractionStrength = ballTemplate.attractionStrength or nil, -- Set the attraction strength if it exists
                currentAngle = ballTemplate.currentAngle or nil,
                orbitRadius = ballTemplate.orbitRadius or nil,
                ammoMult = ballTemplate.ammoMult or 1, -- Set the ammo multiplier if it exists
                counter = ballTemplate.counter or nil,
                onBrickBounce = ballTemplate.onBrickBounce or nil,
                onBrickDestroyed = ballTemplate.onBrickDestroyed or nil,
                onWallBounce = ballTemplate.onWallBounce or nil,
                onShoot = ballTemplate.onShoot or nil,
                onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                onPaddleBounce = ballTemplate.onPaddleBounce or nil,
                shooting = ballTemplate.shooting or false, -- Set the shooting state if it exists
                onBulletHit = ballTemplate.onBulletHit or nil,
                onBuy = ballTemplate.onBuy or nil, -- Function to call when the ball is
                canBuy = ballTemplate.canBuy or true, -- Function to check if the ball can be bought
                damageDealt = 0,
                queuedUpgrades = {},
                angle = ballTemplate.angle or nil,
                stats = {} -- Set the initial cooldown
            }
            for statName, statValue in pairs(ballTemplate.stats) do
                newBallType.stats[statName] = statValue -- Copy other stats as well
            end
            if newBallType.stats.ammo ~= nil then
                -- newBallType.stats.ammo = getStat(newBallType.name, "ammo")
            end
            unlockedBallTypes[ballName] = newBallType -- Add the new ball type to the unlockedBallTypes dictionary
            stats = unlockedBallTypes[ballName].stats -- Get the stats of the new ball type
        else 
            for _, ballType in pairs(unlockedBallTypes) do
                if ballType.name == ballName then
                    stats = ballType.stats -- Get the stats of the existing ball type
                    ballType.amount = ballType.amount + 1 -- Increase the amount of the ball in the list
                    break -- Exit the loop once the ball type is found
                end
            end
        end
        if not stats then
            print("Error: Ball type '" .. ballName .. "' not found in unlockedBallTypes. But, " .. ballName .. " is not a new ball")
            return
        end
        if ballTemplate.type == "ball" then
            local loops = (Player.currentCore == "Damage Core") and 1 or (singleBall and 1 or (getStatItemsBonus("amount", ballTemplate) + (Player.permanentUpgrades.amount or 0) + 1)) * (Player.currentCore == "Madness Core" and 2 or 1)
            loops = Player.currentCore == "IncrediCore" and 1 or loops
            for i=1, loops do
                local totalSpeed = getStat(ballName, "speed")
                local speedX = math.random(-totalSpeed*0.6, totalSpeed*0.6)
                local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
                local newBall = {
                    type = "ball",
                    name = ballTemplate.name,
                    x = screenWidth / 2 + math.random(-50, 50),
                    y = math.max(getHighestBrickY() + ballTemplate.radius + 10, screenHeight/4) + math.random(-50, 50),
                    speedMult = ballTemplate.speedMult or 1,
                    radius = ballTemplate.radius * 1.5,
                    drawSizeBoost = ballTemplate.drawSizeBoost or 1,
                    drawSizeBoostTweens = {},
                    onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                    currentlyOverlappingBricks = {},
                    attractionStrength = ballTemplate.attractionStrength or nil,
                    stats = stats,
                    speedX = speedX,
                    speedY = speedY,
                    dead = false,
                    trail = {},
                    speedMultiplier = 1
                }
                local ballAmount = 0
                for _, ball in ipairs(Balls) do
                    if ball.name == ballName then
                        ballAmount = ballAmount + 1
                    end
                end
                if (Player.currentCore == "Damage Core" and ballAmount < 1 or true) then
                    table.insert(Balls, newBall)
                end
            end
        end

        -- Call the onBuy function if it exists
        if ballList[ballName].onBuy then
            ballList[ballName].onBuy()
        end
    else
        print("Error: Ball type '" .. ballName .. "' does not exist in ballList.")
    end
    print("Added ball: " .. ballName .. ", total balls: " .. #Balls .. ", unlocked ball types: " .. #unlockedBallTypes)
end

function Balls.getMinX()
    local minX = math.huge
    for _, ball in ipairs(Balls) do
        if ball.x < minX then
            minX = ball.x
        end
    end
    return minX
end

function Balls.getMaxX()
    local maxX = -math.huge
    for _, ball in ipairs(Balls) do
        if ball.x > maxX then
            maxX = ball.x
        end
    end
    return maxX
end
--increases the particular stat
function Balls.adjustSpeed(ballName)
    for _, ball in ipairs(Balls) do
        if ball.name == ballName then
            local normalisedSpeedX, normalisedSpeedY = normalizeVector(ball.speedX, ball.speedY)
            -- Calculate total speed by adding all bonuses first, then multiply by base speed
            local totalSpeed = getStat(ballName, "speed")
            ball.speedX = totalSpeed * normalisedSpeedX
            ball.speedY = totalSpeed * normalisedSpeedY
        end
    end
end

function ballHitVFX(ball)
    for _, tweenID in ipairs(ball.drawSizeBoostTweens) do
        removeTween(tweenID) -- Remove the previous tween if it exists
    end
    ball.drawSizeBoostTweens = {} -- Clear the previous tweens
    local hitTween = tween.new(0.05, ball, {drawSizeBoost = math.min(ball.drawSizeBoost+1, 3)}, tween.outQuad)
    addTweenToUpdate(hitTween)
    table.insert(ball.drawSizeBoostTweens, hitTween.id) -- Store the tween in the ball's drawSizeBoostTweens table
    Timer.after(0.05, function()
        local hitTweenBack = tween.new(0.2, ball, {drawSizeBoost = 1}, tween.outQuad)
        addTweenToUpdate(hitTweenBack)
        table.insert(ball.drawSizeBoostTweens, hitTweenBack.id)
    end)
end

local function brickCollisionEffects(ball, brick)
    if ball.name ~= "Phantom Ball" then
        ballHitVFX(ball) -- Call the ball hit VFX function
    end  
    if ball.name == "Exploding Ball" or ball.name == "Incrediball" then
        -- Create explosion using new particle system
        local scale = math.max(getStat(ball.name, "range") * 0.5, 1)
        -- Limit Chain Lightning sprite animations to 25 at once
        createSpriteAnimation(ball.x, ball.y, scale/2, explosionVFX, 512, 512, 0.01, 5)

        --Explosion.spawn(ball.x, ball.y, scale)
        
        -- Play explosion sound
        playSoundEffect(explosionSFX, 0.5, 1, false, true)
        
        dealDamage(ball, brick)
        local bricksTouchingCircle = getBricksInCircle(ball.x, ball.y, getStat(ball.name, "range") * 24)
        for _, touchingBrick in ipairs(bricksTouchingCircle) do
            if touchingBrick and touchingBrick ~= brick then -- Ensure not nil and not the original brick
                if touchingBrick.health > 0 then
                    dealDamage(ball, touchingBrick) -- Deal damage to the touched bricks
                end
            end
        end

        -- Decrement the global Chain Lightning sprite count when the animation ends
        local anim = getAnimation and getAnimation(ball.x, ball.y, scale/3, explosionVFX) -- getAnimation must be implemented to retrieve the animation object
        if anim and anim.onComplete then
            local oldOnComplete = anim.onComplete
            anim.onComplete = function(...)
                _G.chainLightningSpriteCount = math.max(0, (_G.chainLightningSpriteCount or 1) - 1)
                if oldOnComplete then oldOnComplete(...) end
            end
        end
    else 
        dealDamage(ball, brick) -- For other ball types, just deal damage to the brick
    end
    -- Check if ball type exists and has onBrickBounce function
    for _, ballType in pairs(unlockedBallTypes) do
        if ballType.name == ball.name then
            if ballType.onBrickBounce then
                ballType.onBrickBounce() -- Call the onBrickBounce function if it exists
            elseif ballType.name == "Lightning Ball" then
                cast("Lightning Ball", brick)
            elseif ballType.name == "Incrediball" then
                cast("Incrediball", brick)
            end
        end
    end
    local chance = hasItem("Four Leafed Clover") and 100 or 50
    if hasItem("Arcane Missiles") and math.random(1,100) <= 100 then
        castArcaneMissile(ball)
    end
    if ball.onBounce then
        ball.onBounce(ball)
    end
end

local function brickCollisionCheck(ball)
    local hitAnyBrick = false

    -- Special handling for phantom ball - needs to check ALL bricks
    if ball.name == "Phantom Ball" then
        -- Initialize overlap tracking table if it doesn't exist
        ball.currentlyOverlappingBricks = ball.currentlyOverlappingBricks or {}

        for _, brick in ipairs(bricks) do
            if not brick.destroyed then
                local wasOverlapping = ball.currentlyOverlappingBricks[brick.id] or false
                local range = getStat(ball.name, "range") * 0.35

                -- Check current overlap state
                local isOverlapping = ball.x + ball.radius * range > brick.x and 
                                    ball.x - ball.radius * range < brick.x + brick.width and
                                    ball.y + ball.radius * range > brick.y and 
                                    ball.y - ball.radius * range < brick.y + brick.height

                if not wasOverlapping and isOverlapping then
                    -- Only deal damage on first overlap
                    ball.currentlyOverlappingBricks[brick.id] = true
                    dealDamage(ball, brick)
                    hitAnyBrick = true
                elseif wasOverlapping and not isOverlapping then
                    -- Clear the overlap state when no longer overlapping
                    ball.currentlyOverlappingBricks[brick.id] = nil
                end
            end
        end
        
        return hitAnyBrick
    end
    
    
    -- Regular ball collision logic
    local ballHitThisFrame = false
    ball.prevX = ball.prevX or ball.x
    ball.prevY = ball.prevY or ball.y
    
    for index, brick in ipairs(bricks) do
        if ballHitThisFrame then break end
        
        if brick.hitLastFrame then
            brick.hitLastFrame = false
        elseif not brick.destroyed then
            -- Collision detection
            if ball.x + ball.radius > brick.x and ball.x - ball.radius < brick.x + brick.width and
               ball.y + ball.radius > brick.y and ball.y - ball.radius < brick.y + brick.height then
                
                -- Determine collision direction based on previous position
                local fromLeft = ball.prevX + ball.radius <= brick.x
                local fromRight = ball.prevX - ball.radius >= brick.x + brick.width
                local fromTop = ball.prevY + ball.radius <= brick.y
                local fromBottom = ball.prevY - ball.radius >= brick.y + brick.height
                
                -- Apply your existing effects
                if Player.currentCore == "Bouncy Core" then
                    ball.speedExtra = math.min((ball.speedExtra or 1) + 4, 12)
                end
                
                brickCollisionEffects(ball, brick)
                
                -- Handle collision response
                if fromLeft or fromRight then
                    ball.speedX = -ball.speedX
                    if fromLeft then
                        ball.x = brick.x - ball.radius - 2
                    else
                        ball.x = brick.x + brick.width + ball.radius + 2
                    end
                elseif fromTop or fromBottom then
                    ball.speedY = -ball.speedY
                    if fromTop then
                        ball.y = brick.y - ball.radius - 2
                    else
                        ball.y = brick.y + brick.height + ball.radius + 2
                    end
                else
                    -- Fallback: use overlap method but prefer vertical bounces
                    -- for balls coming from between bricks
                    ball.speedY = -ball.speedY
                    ball.y = ball.y < brick.y + brick.height / 2 
                        and brick.y - ball.radius - 2 
                        or brick.y + brick.height + ball.radius + 2
                end
                
                -- Your special ball effects
                if ball.name == "Ping-Pong ball" and ball.speedY < 0 then
                    ball.speedY = ball.speedY - 150
                end
                if ball.name == "Magnetic Ball" or ball.name == "Incrediball" then
                    local currentBallSpeed = (unlockedBallTypes[ball.name].stats.speed + getStatItemsBonus("speed", ballList[ball.name]) * 50 + (Player.permanentUpgrades.speed or 0) * 50) * (Player.currentCore == "Madness Core" and 2 or 1)
                    local normalizedSpeedX, normalizedSpeedY = normalizeVector(ball.x - (brick.x + brick.width/2), ball.y - (brick.y + brick.height/2))
                    local speed = math.sqrt(ball.speedX^2 + ball.speedY^2)
                    local knockback = math.max(0.5 * (Player.currentCore == "Madness Core" and 2 or 1) * math.pow((ball.stats.speed + getStatItemsBonus("speed", ballList[ball.name]) * 50 + (Player.perks.speed or 0) * 50 + 250), 0.6), 250)
                    knockback = math.max(math.min(knockback, 1500 - currentBallSpeed),0)
                    ball.speedX = ball.speedX + normalizedSpeedX * knockback
                    ball.speedY = ball.speedY + normalizedSpeedY * knockback
                end
                
                ballHitThisFrame = true
                return true
            end
        end
    end
    
    -- Store current position for next frame
    ball.prevX = ball.x
    ball.prevY = ball.y
    
    return false
end

local function paddleCollisionCheck(ball, paddle)
    local effectiveRadius = ball.name == "Phantom Ball" and getStat(ball.name, "range") * 12 or ball.radius
    if ball.x + effectiveRadius > paddle.x and ball.x - effectiveRadius < paddle.x + paddle.width and
       ball.y + effectiveRadius > paddle.y and ball.y - effectiveRadius < paddle.y + paddle.height  and 
       ((ball.y > paddle.y + paddle.height and ball.speedY < 0) or ball.y < paddle.y + paddle.height and ball.speedY > 0) then
        playSoundEffect(paddleBoopSFX, 0.4, 0.8, false, true)   
        if hasItem("Paddle Defense System") then
            local bulletSpeed = 1500
            local speedX = math.random(-500,500)
            local speed = {x = speedX, y = -math.sqrt(bulletSpeed*bulletSpeed - speedX*speedX)}
            local critChance = hasItem("Four Leafed Clover") and 50 or 25
            local bullet = {
                x = paddle.x + paddle.width/2,
                y = paddle.y - 5,
                speedX = speed.x,
                speedY = speed.y,
                radius = 5,
                stats = {damage = getStat(ball.name, "damage") * ((hasItem("Assassin's Dagger") and math.random(1,100) <= critChance) and 2 or 1), type = "gun"},
                name = "Paddle Defense System",
                type = "bullet",
                golden = (Player.currentCore == "Phantom Core" or hasItem("Phantom Bullets"))
            }
            table.insert(bullets, bullet)
            local chance = hasItem("Four Leafed Clover") and 20 or 10
            if math.random(1,100) <= chance and hasItem("Sudden Mitosis") then
                local totalSpeed = 500
                local speedX = math.random(-totalSpeed*0.6, totalSpeed*0.6)
                local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
                local ballTemplate = ballList["Ball"]
                local newBall = {
                    type = "ball",
                    name = ballTemplate.name,
                    x = paddle.x + paddle.width / 2,
                    y = paddle.y - 6,
                    speedMult = ballTemplate.speedMult or 1,
                    radius = (ballTemplate.radius or 10) * 1.5,
                    drawSizeBoost = 1,
                    drawSizeMult = 0.5,
                    drawSizeBoostTweens = {},
                    onBounce = ballTemplate.onBounce or nil, -- Function to call when the ball bounces off a brick
                    currentlyOverlappingBricks = {},
                    attractionStrength = ballTemplate.attractionStrength or nil,
                    stats = ballTemplate.stats,
                    speedX = speedX,
                    speedY = speedY,
                    dead = false,
                    trail = {},
                    speedMultiplier = 1
                }
                table.insert(Balls, newBall)
                Timer.after(8, function()
                    local ballDeathTween = tween.new(0.5, newBall, {drawSizeMult = 0}, tween.outCubic)
                    addTweenToUpdate(ballDeathTween)
                    Timer.after(0.5, function()
                        for i, b in ipairs(Balls) do
                            if b == newBall then
                                table.remove(Balls, i)
                                break
                            end
                        end 
                    end)
                end)
            end
        end

        ball.speedY = -ball.speedY
        local hitPosition = (ball.x - (paddle.x - ball.radius)) / (paddle.width + ball.radius * 2)
        -- Calculate total speed by adding all bonuses first
        local ballSpeed = getStat(ball.name, "speed")
        ball.speedX = (hitPosition - 0.5) * 2 * math.abs(ballSpeed * 0.99)
        local speedYSquared = math.max(0, ballSpeed^2 - ball.speedX^2)
        ball.speedY = math.sqrt(speedYSquared) * (ball.speedY > 0 and 1 or -1)
        
        ball.speedExtra = math.min((ball.speedExtra or 1) + 5, 12)

        Balls.adjustSpeed(ball.name)
        
        for _, ballType in pairs(unlockedBallTypes) do
            if ballType.onPaddleBounce then
                ballType.onPaddleBounce() -- Call the onPaddleBounce function if it exists
                if Player.perks.paddleSquared then
                    ballType.onPaddleBounce()
                end
            end
        end
        if ball.onBounce then
            ball.onBounce(ball)
        end
        if ball.name == "Ping-Pong ball" then
            ball.speedY = ball.speedY - 150 -- Increase speedY for Ping-Pong ball
        end
        return true
        end
    return false
end

local function wallCollisionCheck(ball)
    local leftWallPosition = usingMoneySystem and statsWidth or 0
    local rightWallPosition = screenWidth - (usingMoneySystem and statsWidth or 0)
    local wallHit = false
    local effectiveRadius = ball.name == "Phantom Ball" and getStat(ball.name, "range") * 12 or ball.radius
    if ball.x - effectiveRadius < leftWallPosition and ball.speedX < 0 then
        ball.speedX = -ball.speedX
        ball.x = leftWallPosition + effectiveRadius -- Ensure the ball is not stuck in the wall
        if Player.currentCore == "Bouncy Core" or hasItem("Bouncy Walls") then
            ball.speedExtra = math.min((ball.speedExtra or 1) + 4, 12)
        end
        if ball.y < screenWidth then
            playSoundEffect(wallBoopSFX, 0.5, 0.6)
        end
        wallHit = true
    elseif ball.x + effectiveRadius > rightWallPosition and ball.speedX > 0 then
        ball.speedX = -ball.speedX
        ball.x = rightWallPosition - effectiveRadius -- Ensure the ball is not stuck in the 
        if Player.currentCore == "Bouncy Core" or hasItem("Bouncy Walls") then
            ball.speedExtra = math.min((ball.speedExtra or 1) + 4, 12)
        end
        if ball.y < screenWidth then
            playSoundEffect(wallBoopSFX, 0.5, 0.6)
        end
        wallHit = true
    end
    if ball.y - effectiveRadius < 0 and ball.speedY < 0 then
        ball.speedY = -ball.speedY
        ball.y = effectiveRadius -- Ensure the ball is not stuck in the wall
        if Player.currentCore == "Bouncy Core" or hasItem("Bouncy Walls") then
            ball.speedExtra = math.min((ball.speedExtra or 1) + 4, 12)
        end
        playSoundEffect(wallBoopSFX, 0.5, 0.6)
        wallHit = true
    elseif ball.y + effectiveRadius > math.max(screenHeight, paddle.y + 100) and ball.speedY > 0 then
        ball.speedY = -ball.speedY
        ball.y = screenHeight - effectiveRadius
        if Player.currentCore == "Bouncy Core" or hasItem("Bouncy Walls") then
            ball.speedExtra = math.min((ball.speedExtra or 1) + 4, 12)
        end
        playSoundEffect(wallBoopSFX, 0.5, 0.6)
        if ball.name == "Ping-Pong ball" and ball.speedY < 0 then
            ball.speedY = ball.speedY - 25 -- Increase speedY for Ping-Pong ball
        end
        wallHit = true
    end
    if wallHit then
        for _, ballType in pairs(unlockedBallTypes) do
            if ballType.onWallBounce then
                ballType.onWallBounce() -- Call the onWallBounce function if it exists
            end
        end

        if ball.onBounce then 
            ball.onBounce(ball)
        end
    end
end

local nearestBrick = nil
local function techUpdate(dt)
    if unlockedBallTypes["Laser"] then
        if unlockedBallTypes["Laser"].charging then
            unlockedBallTypes["Laser"].currentChargeTime = unlockedBallTypes["Laser"].currentChargeTime + dt
            local cooldownValue = Player.currentCore == "Cooldown Core" and 2 or (Player.currentCore == "Madness Core" and 0.5 or 1) * math.max(getStat("Laser", "cooldown") + 2, 1)
            if accelerationOn then
                cooldownValue = cooldownValue * 0.5
            end
            if unlockedBallTypes["Laser"].currentChargeTime >= (cooldownValue) then
                unlockedBallTypes["Laser"].charging = false
                unlockedBallTypes["Laser"].currentChargeTime = 0
                fire("Laser")
            end
        end
    end

    if unlockedBallTypes["Laser Beam"] then
        local laserBeam = unlockedBallTypes["Laser Beam"]
        
        -- If we have the same target brick as last frame, increment timer
        if laserBeamBrick and laserBeamBrick == laserBeamTarget then
            laserBeamTimer = laserBeamTimer + dt
            
            -- Deal damage if we've been on target long enough
            
            local cooldownLength = (Player.currentCore == "Madness Core" and 0.5 or 1) * 1.2/((Player.currentCore == "Damage Core" and 1 or getStat("Laser Beam", "fireRate")))
            if hasItem("Spray and Pray") then
                local sprayMult = hasItem("Four Leafed Clover") and 0.5 or 0.67
                cooldownLength = cooldownLength * sprayMult
            end
            if laserBeamTimer >= cooldownLength and laserBeamBrick.y > -laserBeamBrick.height then
                dealDamage(laserBeam, laserBeamBrick)
                laserBeamTimer = 0  -- Reset timer after damage
                if hasItem("Spray and Pray") then
                    laserBeam.angle = math.random(-100, 100)/10
                else
                    laserBeam.angle = 0
                end
            end
        else
            -- New target or no target, reset timer
            laserBeamTarget = laserBeamBrick
            laserBeamTimer = math.max(laserBeamTimer + dt, 0) -- Decrease timer if not on target
        end
        laserBeamBrick = nil
        local closestDist = math.huge
        local highestBrick
        local angle = -math.rad(laserBeam.angle)
        local startX = paddle.x + paddle.width/2
        local startY = paddle.y
        -- Calculate end point of laser using direction vector from angle
        local dirX = math.sin(angle)  -- X component of direction
        local dirY = -math.cos(angle) -- Y component of direction (negative because we're going up)
        local endX = startX + dirX * screenHeight
        local endY = startY + dirY * screenHeight
        
        for _, brick in ipairs(bricks) do
            if brick.health > 0 and not brick.destroyed then
                -- Check all four sides of the brick for intersection
                local sides = {
                    {brick.x, brick.y + brick.height, brick.x + brick.width, brick.y + brick.height}, -- bottom
                    {brick.x, brick.y, brick.x + brick.width, brick.y}, -- top
                    {brick.x, brick.y, brick.x, brick.y + brick.height}, -- left
                    {brick.x + brick.width, brick.y, brick.x + brick.width, brick.y + brick.height} -- right
                }
                
                for _, side in ipairs(sides) do
                    -- Line intersection check
                    local x1, y1, x2, y2 = side[1], side[2], side[3], side[4]
                    local denominator = (endY - startY) * (x2 - x1) - (endX - startX) * (y2 - y1)
                    
                    if denominator ~= 0 then
                        local ua = ((endX - startX) * (y1 - startY) - (endY - startY) * (x1 - startX)) / denominator
                        local ub = ((x2 - x1) * (y1 - startY) - (y2 - y1) * (x1 - startX)) / denominator
                        
                        if ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1 then
                            local intersectX = x1 + ua * (x2 - x1)
                            local intersectY = y1 + ua * (y2 - y1)
                            local dist = math.sqrt((intersectX - startX)^2 + (intersectY - startY)^2)
                            
                            if dist < closestDist then
                                closestDist = dist
                                highestBrick = brick
                                laserBeamY = intersectY
                            end
                        end
                    end
                end
            end
        end
        laserBeamBrick = highestBrick
    end

    -- Saw Blades damage logic and animation update
    if unlockedBallTypes["Saw Blades"] then
        local sawBlades = unlockedBallTypes["Saw Blades"]
        local numSaws = (Player.currentCore == "Damage Core") and 1 or getStat("Saw Blades", "amount")
        local orbitRadius = sawBlades.orbitRadius * (math.sin(gameTime/2.5)/2 + 1) * 0.9
        local paddleCenterX = paddle.x + paddle.width / 2
        local paddleCenterY = paddle.y + paddle.height / 2
        local speed = getStat("Saw Blades", "speed") * 25
        sawBlades.sawPositions = sawBlades.sawPositions or {}
        sawBlades.sawAnimations = sawBlades.sawAnimations or {}
        sawBlades.damageCooldowns = sawBlades.damageCooldowns or {} -- Initialize cooldown table
        sawBlades.currentAngle = (sawBlades.currentAngle or 0) + speed * (Player.currentCore == "Madness Core" and 2 or 1) * dt * 0.0002
        for i = 1, numSaws do
            local angle = sawBlades.currentAngle + (2 * math.pi * (i - 1) / numSaws)
            local x = paddleCenterX + orbitRadius * math.cos(angle)
            local y = paddleCenterY + orbitRadius * math.sin(angle)
            sawBlades.sawPositions[i] = {x = x, y = y}
            -- Create looping animation only once per saw
            if not sawBlades.sawAnimations[i] then
                sawBlades.sawAnimations[i] = createSpriteAnimation(x, y, 2.5, sawBladesVFX, 64, 64, 0.05, 0, true, 1, 1, 0, {1,1,1,1}, true)
            end
            -- Update animation position
            local anim = getAnimation(sawBlades.sawAnimations[i])
            if anim then
                anim.x = x
                anim.y = y
            end
            -- Saw Blades collision with bricks angle
            for _, brick in ipairs(bricks) do
                if not brick.destroyed and brick.health > 0 then
                    -- Check collision (circle-rectangle)
                    local closestX = math.max(brick.x, math.min(x, brick.x + brick.width))
                    local closestY = math.max(brick.y, math.min(y, brick.y + brick.height))
                    local dx = x - closestX
                    local dy = y - closestY
                    local dist = dx*dx + dy*dy
                    local sawRadius = 50 -- Half of 64px frame, adjust if needed speed
                    if dist <= sawRadius * sawRadius then
                        -- Damage cooldown logic
                        sawBlades.damageCooldowns[i] = sawBlades.damageCooldowns[i] or {}
                        sawBlades.damageCooldowns[i][brick.id] = sawBlades.damageCooldowns[i][brick.id] or 0
                        if sawBlades.damageCooldowns[i][brick.id] <= 0 then
                            dealDamage(unlockedBallTypes["Saw Blades"], brick)
                            sawBlades.damageCooldowns[i][brick.id] = 0.8 -- 1 second cooldown
                            local anim = getAnimation(sawBlades.sawAnimations[i])
                            if anim then
                                -- Cancel only this saw's previous scale tween
                                if anim.scaleTweenID then
                                    removeTween(anim.scaleTweenID)
                                    anim.scaleTweenID = nil
                                end
                                anim.scale = 3.5
                                local sawBladeScaleTween = tween.new(0.25, anim, {scale = 2.5}, tween.inQuad)
                                addTweenToUpdate(sawBladeScaleTween)
                                anim.scaleTweenID = sawBladeScaleTween.id -- Store this tween's ID on the anim
                            end
                        end
                    end
                    -- Cooldown tick down
                    if sawBlades.damageCooldowns[i] and sawBlades.damageCooldowns[i][brick.id] then
                        sawBlades.damageCooldowns[i][brick.id] = math.max(0, sawBlades.damageCooldowns[i][brick.id] - dt)
                    end
                end
            end
        end
    end

    if unlockedBallTypes["Flamethrower"] then
        local flamethrower = unlockedBallTypes["Flamethrower"]
        flamethrower.damageCooldowns = flamethrower.damageCooldowns or {}
        -- Tick down cooldowns for all bricks
        for brickKey, cd in pairs(flamethrower.damageCooldowns) do
            flamethrower.damageCooldowns[brickKey] = math.max(0, cd - dt)
        end
        -- FlamethrowerVFX hitbox logic (shot forward like flames)
        if flamethrower.vfx then
            flamethrower.debugHitboxes = flamethrower.debugHitboxes or {}
            local spawnRate = 2 -- match VFX spawnRate
            local baseX, baseY = flamethrower.vfx.x, flamethrower.vfx.y
            local dir = flamethrower.vfx.direction or -math.pi/2
            local spread = flamethrower.vfx.spread or (math.pi/6)
            local baseSpeed = flamethrower.vfx.baseSpeed or 550
            local speedVariation = flamethrower.vfx.speedVariation or 80
            local boxLife = 0.6 -- seconds
            local boxSize = 50
            -- Spawn new hitboxes if active
            if flamethrower.vfx.active then
                for i = 1, spawnRate do
                    local angle = dir + (math.random() - 0.5) * spread
                    local speed = baseSpeed + (math.random() - 0.5) * speedVariation
                    local vx = math.cos(angle) * speed
                    local vy = math.sin(angle) * speed
                    table.insert(flamethrower.debugHitboxes, {
                        x = baseX,
                        y = baseY,
                        vx = vx,
                        vy = vy,
                        w = boxSize,
                        h = boxSize,
                        life = boxLife,
                        maxLife = boxLife
                    })
                end
            end
            -- Update and remove expired hitboxes
            for i = #flamethrower.debugHitboxes, 1, -1 do
                local hb = flamethrower.debugHitboxes[i]
                hb.x = hb.x + hb.vx * dt
                hb.y = hb.y + hb.vy * dt
                hb.life = hb.life - dt
                -- Optionally shrink hitbox as it ages
                local shrink = 0.5 + 0.5 * (hb.life / hb.maxLife)
                hb.w = boxSize * shrink
                hb.h = boxSize * shrink
                if hb.life <= 0 then
                    table.remove(flamethrower.debugHitboxes, i)
                end
            end
            -- Check overlap with bricks
            for _, brick in ipairs(bricks) do
                if not brick.destroyed and brick.health > 0 then
                    local brickKey = brick.id or brick
                    for _, hb in ipairs(flamethrower.debugHitboxes) do
                        if brick.x < hb.x + hb.w/2 and brick.x + brick.width > hb.x - hb.w/2 and
                           brick.y < hb.y + hb.h/2 and brick.y + brick.height > hb.y - hb.h/2 then
                            flamethrower.damageCooldowns[brickKey] = flamethrower.damageCooldowns[brickKey] or 0
                            if flamethrower.damageCooldowns[brickKey] <= 0 then
                                dealDamage(flamethrower, brick)
                                flamethrower.damageCooldowns[brickKey] = 0.5
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

local function updateShadowBall(shadowBall, dt, id)
    -- Update position
    if hasItem("Homing Bullets") then
        -- Find nearest brick
        local nearestBrick = nil
        local minDist = math.huge

        if shadowBall.y < -100 then
            shadowBall.dead = true
        end
        
        for _, brick in ipairs(bricks) do  -- Use visibleBricks for performance
            if not brick.destroyed and brick.health > 0 then
                local dx = (brick.x + brick.width/2) - shadowBall.x
                local dy = (brick.y + brick.height/2) - shadowBall.y
                local dist = dx * dx + dy * dy -- Square distance is fine, no need for square root

                if dist < minDist and dist > brick.width/2 and brick.y < shadowBall.y then
                    minDist = dist
                    nearestBrick = brick
                end
            end
        end
        
        -- If we found a brick, adjust bullet velocity towards it
        if nearestBrick then
            local dx = (nearestBrick.x + nearestBrick.width/2) - shadowBall.x
            local dy = (nearestBrick.y + nearestBrick.height/2) - shadowBall.y
            local dist = math.sqrt(dx * dx + dy * dy)
            
            -- Normalize direction
            dx = dx / dist
            dy = dy / dist
            
            -- Calculate homing strength (adjust this value to change how aggressive the homing is)
            local homingStrength = 1200 -- pixels per second
            
            -- Adjust velocity (with smooth turning)
            local turnSpeed = 10 -- Lower = more gradual turning, Higher = sharper turning
            shadowBall.speedX = shadowBall.speedX + (dx * homingStrength - shadowBall.speedX) * dt * turnSpeed
            shadowBall.speedY = -math.abs(shadowBall.speedY + (dy * homingStrength - shadowBall.speedY) * dt * turnSpeed)
            local currentSpeed =  math.sqrt(shadowBall.speedX^2 + shadowBall.speedY^2)
            if currentSpeed < 400 then
                shadowBall.speedX = shadowBall.speedX * (400 / currentSpeed)
                shadowBall.speedY = shadowBall.speedY * (400 / currentSpeed)
            end
        end
    end
    shadowBall.x = shadowBall.x + shadowBall.speedX * dt
    shadowBall.y = shadowBall.y + shadowBall.speedY * dt

    -- Initialize per-brick cooldown table if not present
    if not shadowBall.damageCooldowns then
        shadowBall.damageCooldowns = {}
    end
    -- Update cooldown timers
    for brick, timer in pairs(shadowBall.damageCooldowns) do
        shadowBall.damageCooldowns[brick] = math.max(0, timer - dt)
    end

    -- Check for brick collisions
    for _, brick in ipairs(bricks) do
        if not brick.destroyed and brick.health > 0 and brick.y > -brick.height then
            if shadowBall.x + shadowBall.radius > brick.x and 
               shadowBall.x - shadowBall.radius < brick.x + brick.width and
               shadowBall.y + shadowBall.radius > brick.y and 
               shadowBall.y - shadowBall.radius < brick.y + brick.height then

                local cooldown = 10 -- default 10s if not set
                if not shadowBall.damageCooldowns[brick] or shadowBall.damageCooldowns[brick] <= 0 then
                    dealDamage(shadowBall, brick)
                    shadowBall.damageCooldowns[brick] = cooldown
                end
            end
        end
    end


    -- Check wall collisions: bounce on side walls, die on top/bottom
    if shadowBall.x - shadowBall.radius < (usingMoneySystem and statsWidth or 0) and shadowBall.speedX < 0 then
        shadowBall.speedX = -shadowBall.speedX
        shadowBall.x = (usingMoneySystem and statsWidth or 0) + shadowBall.radius
    elseif shadowBall.x + shadowBall.radius > screenWidth - (usingMoneySystem and statsWidth or 0) and shadowBall.speedX > 0 then
        shadowBall.speedX = -shadowBall.speedX
        shadowBall.x = screenWidth - (usingMoneySystem and statsWidth or 0) - shadowBall.radius
    end
    if shadowBall.y < 0 or shadowBall.y > screenHeight then
        shadowBall.dead = true
    end

    -- Update trail
    if not shadowBall.trail then
        shadowBall.trail = {}
    end
    table.insert(shadowBall.trail, {x = shadowBall.x, y = shadowBall.y})
    if #shadowBall.trail > 65 then -- Shorter trail than regular balls
        table.remove(shadowBall.trail, 1)
    end
end

-- Add near the top with other local functions
-- Limit for active Chain Lightning sprite animations
local MAX_CHAIN_LIGHTNING_ANIM = 50
local activeChainLightningAnims = {}

local function countActiveChainLightning()
    local count = 0
    for i = #activeChainLightningAnims, 1, -1 do
        local anim = getAnimation(activeChainLightningAnims[i])
        if not anim or anim.dead then
            table.remove(activeChainLightningAnims, i)
        else
            count = count + 1
        end
    end
    return count
end

-- Wrapper for creating Chain Lightning sprite animations with a limit
function createLimitedChainLightningAnimation(x, y, scale, ...)
    if countActiveChainLightning() >= MAX_CHAIN_LIGHTNING_ANIM then
        return nil -- Do not create more
    end
    local animID = createSpriteAnimation(x, y, scale, ...)
    table.insert(activeChainLightningAnims, animID)
    return animID
end

local function updateDeadBullets(dt)
    -- Update live bullets first
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        
        -- Update bullet position
        bullet.x = bullet.x + bullet.speedX * dt
        bullet.y = bullet.y + bullet.speedY * dt
        
        -- Remove bullets that go off screen
        if bullet.y < 0 or bullet.y > love.graphics.getHeight() or
            bullet.x < 0 or bullet.x > screenWidth then
            bullet.trailFade = 1
            bullet.deathTime = love.timer.getTime()
            table.insert(deadBullets, bullet)
            table.remove(bullets, i)
        end
    end

    -- Then update dead bullets
    for i = #deadBullets, 1, -1 do
        local bullet = deadBullets[i]
        if not bullet.deathTime then
            bullet.deathTime = love.timer.getTime()
        end
        local elapsed = love.timer.getTime() - bullet.deathTime
        local fade = 1 - math.min(elapsed, 1)
        bullet.trailFade = fade
        if bullet.trail and #bullet.trail > 1 then
            local moveFrac = dt / 0.5
            for j = 1, #bullet.trail - 1 do
                local p = bullet.trail[j]
                local nextP = bullet.trail[j+1]
                p.x = p.x + (nextP.x - p.x) * moveFrac
                p.y = p.y + (nextP.y - p.y) * moveFrac
            end
            -- Remove only one point per frame for smoother fade
            table.remove(bullet.trail, 1)
        end
        -- Remove the bullet when the trail is gone or after 1s
        if fade <= 0 or not bullet.trail or #bullet.trail < 2 then
            table.remove(deadBullets, i)
        else
            bullet.x = bullet.x + bullet.speedX * dt
            bullet.y = bullet.y + bullet.speedY * dt
        end
    end
end
                        
local function drawShadowBall(shadowBall)
    -- Draw glow
    love.graphics.setColor(0.2, 0, 0.2, 0.65) -- Orange glow
    love.graphics.circle("fill", shadowBall.x, shadowBall.y, shadowBall.radius * 1.6)

    -- Draw trail
    for i = 1, #(shadowBall.trail or {}) do
        local p = shadowBall.trail[i]
        local t = i / #shadowBall.trail
        local trailRadius = shadowBall.radius * math.pow(t, 2.3)
        -- Gradient from yellow to red
        love.graphics.setColor(t * 0.6, 0, t * 0.6, math.pow(t, 1.25))
        love.graphics.circle("fill", p.x, p.y, trailRadius)
    end

    -- draw ball
    love.graphics.setColor(120/255, 0, 120/255, 1) -- 
    love.graphics.circle("fill", shadowBall.x, shadowBall.y, shadowBall.radius)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

local lightBeamBricksCD = {}
local lightBeamCD = 0
local lightBeamDmgCD = 0.35
local function spellsUpdate(dt)

    -- Update shadowBalls
    for i = #shadowBalls, 1, -1 do
        local shadowBall = shadowBalls[i]
        updateShadowBall(shadowBall, dt, i)
        if shadowBall.dead then
            table.remove(shadowBalls, i)
        end
    end

    -- Update arcane missiles
    for i = #arcaneMissiles, 1, -1 do
        local missile = arcaneMissiles[i]
        if missile.alive then
            local targetBrick = missile.target
            -- Only home if target is still valid
            if targetBrick and not targetBrick.destroyed and targetBrick.health > 0 and targetBrick.y > -targetBrick.height then
                local dx = (targetBrick.x + targetBrick.width/2) - missile.x
                local dy = (targetBrick.y + targetBrick.height/2) - missile.y
                local dist = math.max(10, math.sqrt(dx*dx + dy*dy))
                local attractionStrength = 2500
                local ax = dx / dist * attractionStrength * dt
                local ay = dy / dist * attractionStrength * dt
                missile.vx = missile.vx + ax
                missile.vy = missile.vy + ay
                -- Clamp speed
                local speed = math.sqrt(missile.vx^2 + missile.vy^2)
                local maxSpeed = 700
                if speed > maxSpeed then
                    missile.vx = missile.vx / speed * maxSpeed
                    missile.vy = missile.vy / speed * maxSpeed
                end
            end
            -- Move missile
            missile.x = missile.x + missile.vx * dt
            missile.y = missile.y + missile.vy * dt
            -- Emit trail
            ArcaneMissile.emit(missile.x, missile.y)
            -- Check collision with bricks
            for _, brick in ipairs(bricks) do
                if not brick.destroyed and brick.health > 0 then
                    if missile.x + missile.radius > brick.x and missile.x - missile.radius < brick.x + brick.width and
                       missile.y + missile.radius > brick.y and missile.y - missile.radius < brick.y + brick.height then
                        dealDamage({stats={damage=missile.damage}}, brick)
                        missile.alive = false
                        break
                    end
                end
            end
            -- Remove if off screen
            if missile.y < 0 or missile.y > screenHeight then
                missile.alive = false
            end
        else
            table.remove(arcaneMissiles, i)
        end
    end

    -- Flame Burst spell: damage bricks as the wave reaches them
    if unlockedBallTypes["Flame Burst"] then
        for _, burst in ipairs(FlameBurst.getBursts()) do
            for _, brick in ipairs(bricks) do
                if not brick.destroyed and brick.health > 0 and not burst.hitBricks[brick] then
                    local dx = burst.x - (brick.x + brick.width/2)
                    local dy = burst.y - (brick.y + brick.height/2)
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist <= burst.radius then
                        dealDamage({stats={damage=burst.damage}}, brick)
                        burst.hitBricks[brick] = true
                    end
                end
            end
        end
    end

    if unlockedBallTypes["Fireballs"] then
        local fireballsCooldown = 20/getStat("Fireballs", "fireRate")
        if gameTime - lastFireballsCastTime >= fireballsCooldown then
            cast("Fireballs")
        end
        for i = #fireballs, 1, -1 do
            local fireball = fireballs[i]
            if hasItem("Homing Bullets") then
                -- Find nearest brick
                local nearestBrick = nil
                local minDist = math.huge
                
                for _, brick in ipairs(bricks) do  -- Use visibleBricks for performance
                    if not brick.destroyed and brick.health > 0 then
                        local dx = (brick.x + brick.width/2) - fireball.x
                        local dy = (brick.y + brick.height/2) - fireball.y
                        local dist = dx * dx + dy * dy -- Square distance is fine, no need for square root

                        if dist < minDist and dist > brick.width * 1.25 and brick.y < fireball.y then
                            minDist = dist
                            nearestBrick = brick
                        end
                    end
                end
                
                -- If we found a brick, adjust bullet velocity towards it
                if nearestBrick then
                    local dx = (nearestBrick.x + nearestBrick.width/2) - fireball.x
                    local dy = (nearestBrick.y + nearestBrick.height/2) - fireball.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    
                    -- Normalize direction
                    dx = dx / dist
                    dy = dy / dist
                    
                    -- Calculate homing strength (adjust this value to change how aggressive the homing is)
                    local homingStrength = 800 -- pixels per second
                    
                    -- Adjust velocity (with smooth turning)
                    local turnSpeed = 7 -- Lower = more gradual turning, Higher = sharper turning
                    fireball.speedX = fireball.speedX + (dx * homingStrength - fireball.speedX) * dt * turnSpeed
                    fireball.speedY = -math.abs(fireball.speedY + (dy * homingStrength - fireball.speedY) * dt * turnSpeed)
                    local currentSpeed =  math.sqrt(fireball.speedX^2 + fireball.speedY^2)
                    if currentSpeed < 500 then
                        fireball.speedX = fireball.speedX * (500 / currentSpeed)
                        fireball.speedY = fireball.speedY * (500 / currentSpeed)
                    end
                end
            end
            fireball.x = fireball.x + fireball.speedX * dt
            fireball.y = fireball.y + fireball.speedY * dt
            if fireball.animation == nil then
                local angle = math.atan2(fireball.speedY, fireball.speedX)* 360 / (2 * math.pi)
                print("angle: " .. angle)
                local animID = createSpriteAnimation(fireball.x, fireball.y, 1.5, fireballVFX, 64, 64, 0.05, 0, true, 1, 1, angle, {1,1,1,1}, false, nil, 8)                                        
                fireball.animation = getAnimation(animID)
            else
                fireball.animation.x = fireball.x
                fireball.animation.y = fireball.y
                fireball.animation.angle = math.deg(math.atan2(fireball.speedY, fireball.speedX))
            end
            if fireball.x < 0 and fireball.speedX < 0 then
                fireball.speedX = -fireball.speedX
                -- Update animation angle after bounce
                local angle = math.atan2(fireball.speedY, fireball.speedX) * 180 / math.pi
                if fireball.animation then
                    fireball.animation.angle = angle
                end
            elseif fireball.x > screenWidth and fireball.speedX > 0 then
                fireball.speedX = -fireball.speedX
                local angle = math.atan2(fireball.speedY, fireball.speedX) * 180 / math.pi
                if fireball.animation then
                    fireball.animation.angle = angle
                end
            end
            -- Fireball collision with bricks
            for _, brick in ipairs(bricks) do
                if not brick.destroyed and brick.health > 0 then
                    if fireball.x + fireball.radius > brick.x and fireball.x - fireball.radius < brick.x + brick.width and
                       fireball.y + fireball.radius > brick.y and fireball.y - fireball.radius < brick.y + brick.height then
                        -- Deal damage and create explosion effect
                        dealDamage(unlockedBallTypes["Fireballs"], brick)
                        local scale = getStat("Fireballs", "range") * 0.5
                        createSpriteAnimation(fireball.x, fireball.y, scale, explosionVFX, 512, 512, 0.01, 5)
                        playSoundEffect(explosionSFX, 0.5, 1, false, true)
                        -- Area damage to nearby bricks
                        local area = scale * 24
                        local bricksTouchingCircle = getBricksInCircle(fireball.x, fireball.y, area)
                        for _, touchingBrick in ipairs(bricksTouchingCircle) do
                            if touchingBrick and touchingBrick ~= brick and touchingBrick.health > 0 then
                                dealDamage(fireball, touchingBrick)
                            end
                        end
                        removeAnimation(fireball.animation.id)
                        table.remove(fireballs, i)
                        break
                    end
                end
            end
        end
    end
end

local incrediballColor = {0.5, 0.5, 0.5, 1}
local incrediballColors = {{1, 1, 1, 1},{0.8, 0.4, 0.1, 1},{0, 170/255, 1, 1},{0.6, 0.2, 0.8, 1},{0.5, 0.5, 0.7, 0.6},{1, 0, 0, 1}}
local function incrediBallColorUpdate(alpha)
    local alpha = alpha % 1
    print("color alpha : " .. alpha)
    local alphaStage = math.ceil(alpha * 6)
    local smallerAlphaDelta = (alpha * 6) % 1
    if alphaStage == 1 then
        incrediballColor = lerpColor(incrediballColors[1], incrediballColors[2], smallerAlphaDelta)
    elseif alphaStage == 2 then
        incrediballColor = lerpColor(incrediballColors[2], incrediballColors[3], smallerAlphaDelta)
    elseif alphaStage == 3 then
        incrediballColor = lerpColor(incrediballColors[3], incrediballColors[4], smallerAlphaDelta)
    elseif alphaStage == 4 then
        incrediballColor = lerpColor(incrediballColors[4], incrediballColors[5], smallerAlphaDelta)
    elseif alphaStage == 5 then
        incrediballColor = lerpColor(incrediballColors[5], incrediballColors[6], smallerAlphaDelta)
    elseif alphaStage == 6 then
        incrediballColor = lerpColor(incrediballColors[6], incrediballColors[1], smallerAlphaDelta)
    else 
        print("alpha stage is not supposed to be over 6, wtf is going on")
    end
    
end

function powerupPickup(powerup)
    playSoundEffect(lvlUpSFX, 0.55, 1, false)   
    
    if powerup.type ~= "nuke" and powerup.type ~= "moneyBag" and powerup.type ~= "dollarBill" then
        powerupPopup.type = powerup.type
        powerupPopup.startTime = gameTime
        local inTween = tween.new(0.15, powerupPopup, {scale = 1}, tween.easing.outCirc)
        addTweenToUpdate(inTween)
    end
    print("powerup type : " .. powerup.type)
    if powerup.type == "dollarBill" then
        local moneyGain = math.random(1,6)
        if moneyGain > 2 then
            moneyGain = 1
        end          
        Player.changeMoney(moneyGain);
        createMoneyPopup(moneyGain, paddle.x + paddle.width/2, paddle.y)
    elseif powerup.type == "moneyBag" then
        local moneyGain = math.random(3,5)
        Player.changeMoney(moneyGain)
        createMoneyPopup(moneyGain, paddle.x + paddle.width/2, paddle.y)
    elseif powerup.type == "nuke" then
        for _, brick in ipairs(bricks) do
            if (brick.health > 0) and (brick.y + brick.height > 0) then
                dealDamage({stats = {damage = math.ceil(getAverageBrickHealth()/2.1)}}, brick) -- Deal damage to all bricks
            end
        end
    elseif powerup.type == "freeze" then
        brickFreeze = true
        brickFreezeTime = gameTime
        Timer.after(20, function() 
            local outTween = tween.new(0.15, powerupPopup, {scale = 0}, tween.easing.inCirc)
            addTweenToUpdate(outTween)
            Timer.after(0.15, function()
                powerupPopup.type = nil
            end)
            accelerationOn = false
        end)
    elseif powerup.type == "acceleration" then
        accelerationOn = true
        for _, weapon in pairs(Balls.getUnlockedBallTypes()) do
            if weapon.type == "ball" then
                Balls.adjustSpeed(weapon.name)
            end
        end
        Timer.after(12, function() 
            local outTween = tween.new(0.15, powerupPopup, {scale = 0}, tween.easing.inCirc)
            addTweenToUpdate(outTween)
            Timer.after(0.15, function()
                powerupPopup.type = nil
            end)
            accelerationOn = false
        end)
    elseif powerup.type == "doubleDamage" then
        statDoubled = "damage"
        Timer.after(8, function() 
            local outTween = tween.new(0.15, powerupPopup, {scale = 0}, tween.easing.inCirc)
            addTweenToUpdate(outTween)
            Timer.after(0.15, function()
                powerupPopup.type = nil
            end)
            if statDoubled == "damage" then
                statDoubled = nil
            end
        end)
    end      
end

-- Modify the Balls.update function to include shadowBall updates
function Balls.update(dt, paddle, bricks)
    if Player.levelingUp or Player.choosingUpgrade then
        return
    end
    -- Clean up expired lightning cooldowns
    for brick, lastCastTime in pairs(lightningCooldowns) do
        if love.timer.getTime() - lastCastTime > 0.2 then
            lightningCooldowns[brick] = nil
        end
    end
    
    if addBallsQueued then
        Balls.addBall(commonWeapons[math.random(1, #commonWeapons)])
        Balls.addBall(uncommonWeapons[math.random(1, #uncommonWeapons)])
        addBallsQueued = false
    end
    if unlockedBallTypes["Incrediball"] then
        incrediBallColorUpdate(gameTime/5)
    end
    local leftWallPosition = usingMoneySystem and statsWidth or 0
    local rightWallPosition = screenWidth - (usingMoneySystem and statsWidth or 0)

    -- Reset hitLastFrame for all bricks at the start of each frame
    -- Compute visible bricks ONCE per frame for all logic
    local screenTop = 0
    local screenBottom = love.graphics and love.graphics.getHeight and love.graphics.getHeight() or 1080
    local visibleBricks = {}
    for _, brick in ipairs(bricks) do
        if brick.y + (brick.height or 0) > screenTop - 10 and brick.y < screenBottom + 10 then
            brick.hitLastFrame = false
            table.insert(visibleBricks, brick)
        end
    end

    brickDeathSFXCd = math.max(0, brickDeathSFXCd - dt) -- Decrease cooldown for brick death SFX

    lightningSFXCooldown = math.max(0, lightningSFXCooldown - dt) -- Decrease cooldown for lightning SFX
    -- Store paddle reference for Ballspawn
    local paddleReference = paddle
    updateDeadBullets(dt)
    techUpdate(dt)  
    spellsUpdate(dt)

    -- Update particles
    --Smoke.update(dt)
    Explosion.update(dt)
    ArcaneMissile.update(dt)
    FlameBurst.update(dt)

    shootSFXCooldown = math.max(shootSFXCooldown - dt, 0)

    -- Update rockets
    for i = #rockets, 1, -1 do
        local rocket = rockets[i]
        if hasItem("Homing Bullets") then
            -- Find nearest brick
            local nearestBrick = nil
            local minDist = math.huge
            
            for _, brick in ipairs(bricks) do  -- Use visibleBricks for performance
                if not brick.destroyed and brick.health > 0 then
                    local dx = (brick.x + brick.width/2) - rocket.x
                    local dy = (brick.y + brick.height/2) - rocket.y
                    local dist = dx * dx + dy * dy -- Square distance is fine, no need for square root

                    if dist < minDist and dist > brick.width * 1.25 and brick.y < rocket.y then
                        minDist = dist
                        nearestBrick = brick
                    end
                end
            end
            
            -- If we found a brick, adjust bullet velocity towards it
            if nearestBrick then
                local dx = (nearestBrick.x + nearestBrick.width/2) - rocket.x
                local dy = (nearestBrick.y + nearestBrick.height/2) - rocket.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                -- Normalize direction
                dx = dx / dist
                dy = dy / dist
                
                -- Calculate homing strength (adjust this value to change how aggressive the homing is)
                local homingStrength = 800 -- pixels per second
                
                -- Adjust velocity (with smooth turning)
                local turnSpeed = 7 -- Lower = more gradual turning, Higher = sharper turning
                rocket.speedX = rocket.speedX + (dx * homingStrength - rocket.speedX) * dt * turnSpeed
                rocket.speedY = -math.abs(rocket.speedY + (dy * homingStrength - rocket.speedY) * dt * turnSpeed)
                local currentSpeed =  math.sqrt(rocket.speedX^2 + rocket.speedY^2)
                if currentSpeed < 500 then
                    rocket.speedX = rocket.speedX * (500 / currentSpeed)
                    rocket.speedY = rocket.speedY * (500 / currentSpeed)
                end
            end
        end
        rocket.x = rocket.x + rocket.speedX * dt
        rocket.y = rocket.y + rocket.speedY * dt
        rocket.animation.x = rocket.x
        rocket.animation.y = rocket.y
        rocket.animation.angle = math.deg(math.atan2(rocket.speedY, rocket.speedX)) + 90

        -- Check for collision with bricks
        local hitBrick = false
        -- Calculate offset based on rocket's direction for collision
        local dirX = -math.cos(math.rad(rocket.angle - 90)) * 50
        local dirY = -math.sin(math.rad(rocket.angle - 90)) * 50
        local rocketDrawX = rocket.x + dirX
        local rocketDrawY = rocket.y + dirY
        if bricksInEllipse(rocket.x, rocket.y, 20, 60) then
            playSoundEffect(explosionSFX, 0.5, 1, false, true)
            -- Explosion damage
            local scale = 2 + getStat("Rocket Launcher", "range") * 0.5
            local explosionX, explosionY = rocket.x - math.sin(math.rad(rocket.angle)) * rocket.radius, rocket.y - math.cos(math.rad(rocket.angle)) * rocket.radius
            local touchingBricks = getBricksInCircle((explosionX), (explosionY), scale*25)
            for _, hitBrick in ipairs(touchingBricks) do
                if not hitBrick.destroyed and hitBrick.health > 0 then
                    dealDamage(unlockedBallTypes["Rocket Launcher"], hitBrick)
                    hitBrick.hitLastFrame = true
                end
            end
            createSpriteAnimation((explosionX), (explosionY), scale/3, explosionVFX, 512, 512, 0.01, 0, false)
            hitBrick = true
            removeAnimation(rocket.animation.id)
            table.remove(rockets, i) -- Remove rocket immediately when it hits a brick
            break
        end

        -- Don't continue updating if the rocket was removed
        if not rockets[i] then goto continue end

        -- Make rockets bounce off walls
        local leftWallPosition = usingMoneySystem and statsWidth or 0
        local rightWallPosition = screenWidth - (usingMoneySystem and statsWidth or 0)

        -- Bounce off side walls
        if rocket.x - rocket.radius < leftWallPosition and rocket.speedX < 0 then
            rocket.speedX = -rocket.speedX
            rocket.x = leftWallPosition + rocket.radius
            rocket.animation.x = rocket.x
            rocket.angle = -rocket.angle -- Reflect the angle
            rocket.animation.angle = rocket.angle
            rocket.speedY = rocket.speedY - 50 -- Reduce vertical speed slightly
        elseif rocket.x + rocket.radius > rightWallPosition and rocket.speedX > 0 then
            rocket.speedX = -rocket.speedX
            rocket.x = rightWallPosition - rocket.radius
            rocket.animation.x = rocket.x
            rocket.angle = -rocket.angle -- Reflect the angle
            rocket.animation.angle = rocket.angle
            rocket.speedY = rocket.speedY - 50 -- Reduce vertical speed slightly
        end

        -- Bounce off bottom
        if rocket.y + rocket.radius > screenHeight and rocket.speedY > 0 then
            rocket.speedY = -rocket.speedY -- Bounce off bottom
            rocket.y = screenHeight - rocket.radius
            rocket.angle = 180 - rocket.angle -- Reflect the angle
        end

        -- Remove if it goes off the top
        if rocket.y < -rocket.radius * 2 then
            removeAnimation(rocket.animation.id)
            table.remove(rockets, i)
        end
        ::continue::
    end

    -- update balls
    for _, ball in ipairs(Balls) do -- Corrected loop
        -- Only update non-shadowBall balls here
        if not (ball.type == "spell" and ball.name == "Shadow Ball") then

            local speedMultBeforeChange = ball.speedExtra or 1
            if ball.speedExtra then
                ball.speedExtra = math.max(1, ball.speedExtra - math.pow(ball.speedExtra, 1.75) * dt * 0.5) -- Decrease speed multiplier over time
            end

            local multX, multY = normalizeVector(ball.speedX, ball.speedY)
            local speedExtra = ((ball.name == "Magnetic Ball" or ball.name == "Incrediball") and 0.1 or 1) * (ball.speedExtra or 0)
            local speedMult = 1
            ball.x = ball.x + (ball.speedX + speedExtra * multX * 50) * ball.speedMult * dt * (Player.currentCore == "Madness Core" and 2 or 1) * speedMult
            ball.y = ball.y + (ball.speedY + speedExtra * multY * 50) * ball.speedMult * dt * (Player.currentCore == "Madness Core" and 2 or 1) * speedMult

            if ball.type == "ball" then
                local trailSpacing = 3 -- Distance between trail points
                if not ball.lastTrailPos then
                    ball.lastTrailPos = {x = ball.x, y = ball.y}
                    table.insert(ball.trail, {x = ball.x, y = ball.y})
                else
                    local dx = ball.x - ball.lastTrailPos.x
                    local dy = ball.y - ball.lastTrailPos.y
                    local distanceMoved = math.sqrt(dx * dx + dy * dy)
                    table.insert(ball.trail, {x = ball.x, y = ball.y})
                    ball.lastTrailPos.x = ball.x
                    ball.lastTrailPos.y = ball.y
                end

                -- Limit the trail length
                while #ball.trail > ballTrailLength do
                    table.remove(ball.trail, 1)
                end
            end

            -- Ball collision with paddle
            paddleCollisionCheck(ball, paddle)

            -- Ball collision with bricks (use visibleBricks for all balls)
            local hitBrickThisFrame = brickCollisionCheck(ball, visibleBricks, Player)

            -- Ball collision with walls
            if not hitBrickThisFrame then
                wallCollisionCheck(ball)
            end

            -- Magnetic ball behavior (use visibleBricks)
            if ball.name == "Magnetic Ball" or hasItem("Electromagnetic Alignment") or ball.name == "Incrediball" then
                -- Update nearest brick every 0.1 seconds instead of every frame
                ball.magneticUpdateTimer = (ball.magneticUpdateTimer or 0) + dt
                if ball.magneticUpdateTimer >= 0.1 then
                    ball.magneticUpdateTimer = 0
                    
                    local nearestBrick = nil
                    local minDistSq = math.huge
                    local MAX_RANGE_SQ = 500 * 500 -- Only check bricks within 500 units
                    
                    for _, brick in ipairs(visibleBricks) do
                        if not brick.destroyed and brick.health > 0 and brick.y > -brick.height/2 then
                            local dx = (brick.x + brick.width/2) - ball.x
                            local dy = (brick.y + brick.height/2) - ball.y
                            local distSq = dx*dx + dy*dy
                            
                            if distSq < MAX_RANGE_SQ and distSq < minDistSq then
                                minDistSq = distSq
                                nearestBrick = brick
                            end
                        end
                    end
                    
                    ball.cachedNearestBrick = nearestBrick
                    ball.cachedNearestDistSq = minDistSq
                end
                
                -- Apply magnetic attraction using cached brick
                if ball.cachedNearestBrick then
                    local nearestBrick = ball.cachedNearestBrick
                    local dist = math.sqrt(ball.cachedNearestDistSq)
                    
                    local attractionStrength = ball.attractionStrength or 425
                    local dx = (nearestBrick.x + nearestBrick.width/2) - ball.x
                    local dy = (nearestBrick.y + nearestBrick.height/2) - ball.y
                    -- Recalculate dist for current frame (brick might have moved slightly)
                    dist = math.sqrt(dx*dx + dy*dy)
                    
                    local attraction = mapRange((attractionStrength / math.max(dist, 10)) * math.pow((ball.stats.speed + getStatItemsBonus("speed", ball) * 50 + (ball.speedExtra or 0) * 15) * (Player.currentCore == "Madness Core" and 2 or 1), 1.45), 1, 10, 1, 20) * 0.0175
                    attraction = attraction * mapRangeClamped(ball.stats.speed + getStatItemsBonus("speed", ball) * 50 + (ball.speedExtra or 0)*10, 1, 500, 0.5, 2)
                    local angle = math.atan2(dy, dx)
                    ball.speedX = ball.speedX + math.cos(angle) * attraction * dt
                    ball.speedY = ball.speedY + math.sin(angle) * attraction * dt
                    
                    -- Normalize velocity to maintain ball speed
                    local speed = math.sqrt(ball.speedX * ball.speedX + ball.speedY * ball.speedY)
                    local originalSpeed = getStat(ball.name, "speed")
                    if speed > originalSpeed then
                        local scale = originalSpeed / speed
                        if ball.speedX > 0 then
                            ball.speedX = math.max(ball.speedX * scale, ball.speedX - dt*200 * mapRange(math.abs(ball.speedX - ball.speedX * scale), 0, 1000, 1, 10))
                        else
                            ball.speedX = math.min(ball.speedX * scale, ball.speedX + dt*200 * mapRange(math.abs(ball.speedX - ball.speedX * scale), 0, 1000, 1, 10))
                        end
                        if ball.speedY > 0 then
                            ball.speedY = math.max(ball.speedY * scale, ball.speedY - dt*200 * mapRange(math.abs(ball.speedY - ball.speedY * scale), 0, 1000, 1, 10))
                        else
                            ball.speedY = math.min(ball.speedY * scale, ball.speedY + dt*200 * mapRange(math.abs(ball.speedY - ball.speedY * scale), 0, 1000, 1, 10))
                        end
                    end
                    if speed > originalSpeed * 1.5 then
                        local scale = (originalSpeed * 1.5) / speed
                        ball.speedX = ball.speedX * scale
                        ball.speedY = ball.speedY * scale
                    end
                end
            end
        end
    end

    -- Update bullets
    for i = #bullets, 1, -1 do  -- Iterate backwards to safely remove bullets
        local bullet = bullets[i]
        bullet.distanceTraveled = bullet.distanceTraveled or 0
        bullet.hasSplit = bullet.hasSplit or false
        
        -- Handle Homing Bullets
        if hasItem("Homing Bullets") then
            -- Find nearest brick
            local nearestBrick = nil
            local minDist = math.huge
            
            for _, brick in ipairs(visibleBricks) do  -- Use visibleBricks for performance
                if not brick.destroyed and brick.health > 0 then
                    local dx = (brick.x + brick.width/2) - bullet.x
                    local dy = (brick.y + brick.height/2) - bullet.y
                    local dist = dx * dx + dy * dy -- Square distance is fine, no need for square root
                    
                    if dist < minDist and dist > brick.width * 1.25 then
                        minDist = dist
                        nearestBrick = brick
                    end
                end
            end
            
            -- If we found a brick, adjust bullet velocity towards it
            if nearestBrick then
                local dx = (nearestBrick.x + nearestBrick.width/2) - bullet.x
                local dy = (nearestBrick.y + nearestBrick.height/2) - bullet.y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                -- Normalize direction
                dx = dx / dist
                dy = dy / dist
                
                -- Calculate homing strength (adjust this value to change how aggressive the homing is)
                local homingStrength = 2500 -- pixels per second
                
                -- Adjust velocity (with smooth turning)
                local turnSpeed = 10 -- Lower = more gradual turning, Higher = sharper turning
                bullet.speedX = bullet.speedX + (dx * homingStrength - bullet.speedX) * dt * turnSpeed
                bullet.speedY = -math.abs(bullet.speedY + (dy * homingStrength - bullet.speedY) * dt * turnSpeed)
                local currentSpeed =  math.sqrt(bullet.speedX^2 + bullet.speedY^2)
                if currentSpeed < 1000 then
                    bullet.speedX = bullet.speedX * (1000 / currentSpeed)
                    bullet.speedY = bullet.speedY * (1000 / currentSpeed)
                end
            end
        end
        
        -- Store last position for raycast
        local lastX, lastY = bullet.x, bullet.y
        -- Update position
        bullet.x = bullet.x + bullet.speedX * dt
        bullet.y = bullet.y + bullet.speedY * dt
        -- Calculate movement vector
        local moveX = bullet.x - lastX
        local moveY = bullet.y - lastY
        -- Number of collision checks along the path (more for faster bullets)
        local steps = math.max(1, math.ceil(math.sqrt(moveX * moveX + moveY * moveY) / bullet.radius))
        -- Bullet trail logic (longer, smoother)
        bullet.trail = bullet.trail or {}
        -- Insert at the end for natural order (oldest at 1, newest at #trail)
        -- Add interpolated point between last and current if possible
        if #bullet.trail > 0 then
            local last = bullet.trail[#bullet.trail]
            local mid = {x = (last.x + bullet.x) * 0.5, y = (last.y + bullet.y) * 0.5}
            table.insert(bullet.trail, mid)
        end
        table.insert(bullet.trail, {x = bullet.x, y = bullet.y})
        local maxTrail = 15
        while #bullet.trail > maxTrail do
            table.remove(bullet.trail, 1)
        end
        -- multishot logic
        if Player.perks.multishot or hasItem("Split Shooter") then
            bullet.distanceTraveled = bullet.distanceTraveled + math.sqrt(bullet.speedX^2 + bullet.speedY^2) * dt
            if not bullet.hasSplit and bullet.distanceTraveled > 50 then
                bullet.hasSplit = true
                local chance = hasItem("Four Leafed Clover") and 50 or 25
                if math.random(1,100) <= chance then
                    local angle = math.atan2(bullet.speedY, bullet.speedX)
                    local speed = math.sqrt(bullet.speedX^2 + bullet.speedY^2)
                    local spread = math.rad(8)
                    for _, offset in ipairs({-spread, spread}) do
                        local newAngle = angle + offset
                        local newBullet = {}
                        for k,v in pairs(bullet) do newBullet[k]=v end -- shallow copy
                        newBullet.type = "bullet"
                        newBullet.speedX = math.cos(newAngle) * speed
                        newBullet.speedY = math.sin(newAngle) * speed
                        newBullet.hasSplit = true
                        newBullet.distanceTraveled = bullet.distanceTraveled
                        -- Deep copy stats
                        newBullet.stats = {}
                        for k,v in pairs(bullet.stats or {}) do newBullet.stats[k]=v end
                        -- Deep copy trail so each split bullet has its own trail
                        if bullet.trail then
                            newBullet.trail = {}
                            for i, pt in ipairs(bullet.trail) do
                                newBullet.trail[i] = {x = pt.x, y = pt.y}
                            end
                        end
                        -- Ensure golden property is preserved for Golden Gun
                        if bullet.golden or bullet.name == "Golden Gun" then
                            newBullet.golden = true
                        end
                        table.insert(bullets, newBullet)              
                    end
                    table.remove(bullets, i) 
                end
            end
        end
        -- Emit smoke particles behind the bullet
        local dirX = -bullet.speedX / math.sqrt(bullet.speedX^2 + bullet.speedY^2)
        local dirY = -bullet.speedY / math.sqrt(bullet.speedX^2 + bullet.speedY^2)

        -- Check for collision with visible bricks only
        if bullet.y >= 0 then
            local hitBrick = false
            -- Golden bullets: only damage each brick once
            local shouldRemoveBullet = false
            if bullet.golden then
                bullet.hitBricks = bullet.hitBricks or {}
            end
            for _, brick in ipairs(visibleBricks) do
                if not brick.destroyed and not brick.hitLastFrame then
                    if bullet.x + bullet.radius * 2 > brick.x and bullet.x - bullet.radius * 4 < brick.x + brick.width and
                        bullet.y + bullet.radius * 2 > brick.y and bullet.y - bullet.radius * 4 < brick.y + brick.height then
                        -- For golden bullets, check if this brick was already hit
                        if bullet.golden then
                            bullet.hitBricks = bullet.hitBricks or {}
                            if bullet.hitBricks[brick] then
                                -- Already hit this brick, skip
                                goto next_brick
                            else
                                bullet.hitBricks[brick] = true
                            end
                        end
                        if not bullet.hasTriggeredOnBulletHit then
                            local chance = hasItem("Four Leafed Clover") and 50 or 25
                            if hasItem("Tesla Bullets") and math.random(1,100) <= chance then
                                cast("Chain Lightning", brick, bullet.stats.damage)
                            end
                            bullet.hasTriggeredOnBulletHit = true
                        end
                        local damage = math.min((bullet.stats.damage or 1), brick.health)
                        -- Deal damage to the brick
                        local kill = dealDamage(bullet, brick)

                        if hasItem("Phantom Bullets") then
                            bullet.stats.damage = bullet.stats.damage - 2
                        end
                        if (not kill and (not bullet.golden)) or (hasItem("Phantom Bullets") and bullet.stats.damage <= 0) then
                            shouldRemoveBullet = true
                            break -- Exit brick loop once we know bullet should be removed
                        end
                        hitBrick = true
                        break
                    end
                end
                ::next_brick::
            end
            
            -- Remove bullet after brick loop if needed
            if shouldRemoveBullet then
                bullet.trailFade = 1
                bullet.deathTime = love.timer.getTime()
                table.insert(deadBullets, bullet)
                table.remove(bullets, i)
                goto continue
            end
            
            if hitBrick then
                goto continue  -- Skip to next bullet if we hit a brick (unless golden)
            end
        end

        -- Make bullets bounce off side walls and bottom
        if bullet.x - bullet.radius < leftWallPosition and bullet.speedX < 0 then
            bullet.speedX = -bullet.speedX
            bullet.x = leftWallPosition + bullet.radius -- Ensure the bullet is not stuck in the wall
            bullet.speedY = bullet.speedY - 50
        elseif bullet.x + bullet.radius > rightWallPosition and bullet.speedX > 0 then
            bullet.speedX = -bullet.speedX
            bullet.x = rightWallPosition - bullet.radius -- Ensure the bullet is not stuck in the wall
            bullet.speedY = bullet.speedY - 50
        end
        if bullet.y + bullet.radius > screenHeight then
            bullet.speedY = -bullet.speedY -- Bounce off bottom with reduced speed
            bullet.y = screenHeight - bullet.radius -- Ensure the bullet is not stuck in the wall
        end
        -- Remove bullets that go off-screen
        if bullet.y <= -200 then
            bullet.trailFade = 1
            bullet.deathTime = love.timer.getTime()
            table.insert(deadBullets, bullet)
            table.remove(bullets, i)
        end

        ::continue::
    end
    for id, anim in pairs(fireAnims) do
        local animation = getAnimation(anim)
        -- Find the brick with this id
        local brick = nil
        for _, b in ipairs(bricks) do
            if b and b.id == id then
                brick = b
                break
            end
        end
        if animation and brick and not brick.destroyed then
            animation.x = brick.x + brick.width / 2
            animation.y = brick.y + brick.height / 2 - 20
        elseif animation then
            -- If the brick is gone or destroyed, clean up the animation
            removeAnimation(anim)
            fireAnims[id] = nil
        end
    end
    -- Failsafe: Prevent Flamethrower VFX update during shop/levelingUp phase
    local flamethrower = unlockedBallTypes["Flamethrower"]
    if flamethrower and flamethrower.vfx then
        if Player.levelingUp and not Player.choosingUpgrade then
            flamethrower.vfx:stop()
            -- Optionally clear particles to avoid leftover lag
            --flamethrower.vfx:clear()
        else
            flamethrower.vfx:setPosition(paddle.x + paddle.width / 2, paddle.y)
            flamethrower.vfx:update(dt)
        end
    end

    for i=#powerups, 1, -1 do
        -- powerup update logic
        local orb = powerups[i]

        -- movement logic
        orb.y = orb.y + orb.speedY * dt
        orb.x = orb.x + orb.speedX * dt
        local totalSpeed = math.sqrt(orb.speedX * orb.speedX + orb.speedY * orb.speedY)
        local maxSpeed = 400
        if totalSpeed > maxSpeed then
            orb.speedX = orb.speedX * maxSpeed / totalSpeed
            orb.speedY = orb.speedY * maxSpeed / totalSpeed
        end
        -- wall bounce logic
        if orb.x < 0 then orb.speedX = -orb.speedX end
        if orb.x > screenWidth then orb.speedX = -orb.speedX end
        --[[if orb.y > screenHeight then
            if orb.bounceAmount > 0 then
                orb.y = screenHeight
                orb.speedY = math.min(-orb.speedY * 0.85, -500)
                orb.bounceAmount = orb.bounceAmount - 1
            else
                table.remove(powerups, i)
            end
        end]]
        if paddle.x < orb.x and orb.x < paddle.x + paddle.width then
            local attractionStrength = 1100
            local angle = math.atan2((paddle.y + paddle.height/2) - orb.y, (paddle.x + paddle.width/2) - orb.x)
            orb.speedX = orb.speedX + math.cos(angle) * attractionStrength * dt
            orb.speedY = orb.speedY + math.sin(angle) * attractionStrength * dt
        else
            orb.speedY = math.min(orb.speedY + 300 * dt, 300) -- gravity effect
        end

        orb.angle = (orb.angle or 0) + dt * 1

        -- attraction to paddle
        local closestX = math.max(paddle.x, math.min(orb.x, paddle.x + paddle.width))
        local closestY = math.max(paddle.y, math.min(orb.y, paddle.y + paddle.height))
        
        local dx = orb.x - closestX
        local dy = orb.y - closestY
        local distanceToPaddle = math.sqrt(dx * dx + dy * dy)
        --[[if orb.type == "moneyBill" and orb.x > paddle.x and orb.x < paddle.x + paddle.width then    
            print("distance to paddle: " .. distanceToPaddle)
            local attractionStrength = mapRangeClamped(distanceToPaddle, 50, 500, 10000, 500)
            local angle = math.atan2(dy, dx)
            orb.speedX = orb.speedX - math.cos(angle) * attractionStrength * dt
            orb.speedY = orb.speedY - math.sin(angle) * attractionStrength * dt
        end]]

        -- orb pickup when close enough
        if distanceToPaddle < 10 then
            -- xp orb pickup
            
            powerupPickup(orb)
                
            table.remove(powerups, i)
        end

        -- trail logic (ring-buffer to avoid allocations and table shifting)
        orb._lastTrailTime = orb._lastTrailTime or 0
        if gameTime - orb._lastTrailTime >= POWERUP_TRAIL_SPACING then -- Add trail points at controlled spacing
            orb._lastTrailTime = gameTime
            -- compute insertion index (newest)
            local insertIndex = ((orb._trailHead + orb._trailCount - 1) % POWERUP_TRAIL_MAX) + 1
            if orb._trailCount == POWERUP_TRAIL_MAX then
                -- buffer full: advance head (overwrite oldest)
                orb._trailHead = (orb._trailHead % POWERUP_TRAIL_MAX) + 1
            else
                orb._trailCount = orb._trailCount + 1
            end
            local pt = orb.trail[insertIndex]
            pt.x = orb.x
            pt.y = orb.y
            pt.alpha = 1
        end
        -- fade all points (no removals)
        for k = 1, POWERUP_TRAIL_MAX do
            local pt = orb.trail[k]
            if pt and pt.alpha and pt.alpha > 0 then
                pt.alpha = pt.alpha - dt * 3
                if pt.alpha < 0 then pt.alpha = 0 end
            end
        end
    end
end


local function laserShoot()
    unlockedBallTypes["Laser"].currentChargeTime = 0
    laserAlpha.a = 1
    local laserTween = tween.new(0.5, laserAlpha, {a = 0}, tween.inQuad)
    addTweenToUpdate(laserTween)
    for _, brick in ipairs(bricks) do
        if not brick.destroyed and brick.y > -brick.height then
            if paddle.x < brick.x + brick.width and paddle.x + paddle.width > brick.x then
                dealDamage({name = "Laser", stats = {damage = unlockedBallTypes["Laser"].stats.damage}, speedX = 0, speedY = -1}, brick)
            end
        end
    end
end

local function drawBullets()
    -- Draw bullet trails (active bullets)
    for _, bullet in ipairs(bullets) do
        local scale = 1
        if bullet.trail then
            local trailLen = #bullet.trail
            local step = 2
            for i = trailLen, 2, -step do
                local p1 = bullet.trail[i]
                local p2 = bullet.trail[math.max(i-step, 1)]
                if p1 and p2 then
                    local t = (i-1) / trailLen
                    local radius = ((bullet.radius or 5) * t * 0.75 + 0.5) * scale
                    local alpha = 1
                    if bullet.golden or bullet.name == "Golden Gun" then
                        -- Golden Gun: gold to orange gradient
                        local r = 1
                        local g = 0.84 * (1-t) + 0.5 * t
                        local b = 0 * (1-t) + 0.1 * t
                        love.graphics.setColor(r, g, b, alpha)
                    else
                        local r = 1
                        local g = t
                        local b = 0
                        love.graphics.setColor(r, g, b, alpha)
                    end
                    love.graphics.setLineWidth(radius * 1.5)
                    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                end
            end
        end
        -- Draw the bullets themselves
        local radius = (bullet.radius or 5)/2
        if bullet.golden or bullet.name == "Golden Gun" then
            love.graphics.setColor(1, 0.84, 0, 1) -- gold core
        else
            love.graphics.setColor(1, 1, 0, 1)
        end
        love.graphics.circle("fill", bullet.x, bullet.y, radius)
    end
    -- Draw fading trails for dead bullets
    for _, bullet in ipairs(deadBullets) do
        local fade = bullet.trailFade or 1
        if bullet.trail then
            local trailLen = #bullet.trail
            for i = trailLen, 2, -1 do
                local p1 = bullet.trail[i]
                local p2 = bullet.trail[i-1]
                local p3 = {x = 0, y = 0}
                p3.x, p3.y = normalizeVector(p2.x - p1.x, p2.y - p1.y)
                local mult = 1.0
                p2 = {x = p2.x - p3.x * mult, y = p2.y - p3.y * mult}
                if p1 and p2 then
                    local t = (i-1) / trailLen
                    local radius = (bullet.radius or 5) * t
                    local alpha = 1 * fade
                    if bullet.golden or bullet.name == "Golden Gun" then
                        -- Golden Gun: gold to orange gradient
                        local r = 1
                        local g = 0.84 * (1-t) + 0.5 * t
                        local b = 0 * (1-t) + 0.1 * t
                        love.graphics.setColor(r, g, b, alpha)
                    else
                        local r = 1
                        local g = t
                        local b = 0
                        love.graphics.setColor(r, g, b, alpha)
                    end
                    love.graphics.setLineWidth(radius * 1.5)
                    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                end
            end
        end
        -- Fade out the bullet core as well
        if bullet.trailFade then
            if bullet.golden or bullet.name == "Golden Gun" then
                love.graphics.setColor(1, 0.84, 0, bullet.trailFade * bullet.trailFade * 0.5)
            else
                love.graphics.setColor(1, 1, 1, bullet.trailFade * bullet.trailFade * 0.5)
            end
            love.graphics.circle("fill", bullet.x, bullet.y, (bullet.radius or 5) * 0.05)
        end
    end
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end


local function techDraw()
    if unlockedBallTypes["Laser"] then
        love.graphics.setColor(1, 1, 1, 0.6)

        -- draw charging bars
        if unlockedBallTypes["Laser"].charging then
            local cooldownValue = (((Player.currentCore == "Cooldown Core" and 2 or math.max(getStat("Laser", "cooldown") + 2, 1))) * (Player.currentCore == "Madness Core" and 0.5 or 1))
            if accelerationOn then
                cooldownValue = cooldownValue * 0.5
            end
            local chargeProgress = unlockedBallTypes["Laser"].currentChargeTime / cooldownValue
            local opacityMult = mapRangeClamped(chargeProgress, 0.6, 1, 0, 0.75)
            love.graphics.setColor(0.85, 0.85, 0.85, opacityMult)
            love.graphics.rectangle("fill", paddle.x, 0, 1, paddle.y)
            love.graphics.rectangle("fill", paddle.x + paddle.width, 0, 1, paddle.y)
            love.graphics.setColor(0.85, 0.85, 0.85, opacityMult)
            local barWidth = math.min(paddle.width/2, paddle.width/2 * chargeProgress)
            love.graphics.rectangle("fill", paddle.x + paddle.width/2 - barWidth, 0, 1, paddle.y)
            love.graphics.rectangle("fill", paddle.x + paddle.width/2 + barWidth, 0, 1, paddle.y)
        end
        -- Draw laser beam
        love.graphics.setColor(0, 1, 25/255, laserAlpha.a)
        love.graphics.rectangle("fill", paddle.x, 0, paddle.width, paddle.y)
    end

    -- Draw Laser Beam
    if unlockedBallTypes["Laser Beam"] then
        -- Draw the actual Laser Beam
        -- Calculate charge progress
        local chargeProgress = laserBeamTimer / ((1.35/((Player.currentCore == "Damage Core" and 1 or getStat("Laser Beam", "fireRate")))))
        if hasItem("Spray and Pray") then
            local sprayMult = hasItem("Four Leafed Clover") and 2 or 1.5
            chargeProgress = math.min(1, chargeProgress * sprayMult)
        end
        -- Interpolate color from grey to red based on charge
        local r = 0.35 + (1 - 0.35) * chargeProgress
        local g = 0.35 - 0.35 * chargeProgress
        local b = 0.35 - 0.35 * chargeProgress
        local a = 0.25 + 0.75 * chargeProgress
        love.graphics.setColor(r, g, b, a)
        local angle = -math.rad(unlockedBallTypes["Laser Beam"].angle)
        local startX = paddle.x + paddle.width/2
        local startY = paddle.y
        local beamLength
        
        if laserBeamBrick then
            beamLength = math.sqrt((laserBeamY - startY)^2 + ((startX + math.sin(angle) * (startY - laserBeamY)) - startX)^2)
        else
            beamLength = startY  -- Full length to top of screen
        end
        
        love.graphics.push()
        love.graphics.translate(startX, startY)
        love.graphics.rotate(angle)  -- Removed extra negative to match collision detection
        love.graphics.rectangle("fill", -1, -beamLength, 2, beamLength)
        love.graphics.pop()
    end    

    if unlockedBallTypes["Gun Turrets"] then
        love.graphics.setColor(1,1,1,1)
        for _, turret in ipairs(turrets) do
            local angle = math.atan2(-turret.y, screenWidth/2 - turret.x)
            drawImageCentered(turretBaseImg, turret.x, turret.y, turret.radius * 0.75, turret.radius * 0.75, turret.angleOffset)
            drawImageCentered(turretGunImg, turret.x, turret.y, turret.radius * 145/280, turret.radius * 145/144, turret.angle + turret.angleOffset, 0, turret.radius * 145/144 * 1/4)
        end
    end

    -- Draw Gravity pulse tech range and target
    --[[ Maybe I could recycle this for an item
    if Player.currentCore == "Magnetic Core" and nearestBrick then
        if nearestBrick.health > 0 and not nearestBrick.dead then
            if gravityWell.techTarget then
                -- Initialize time if it doesn't exist
                gravityWell.animTime = (gravityWell.animTime or 0) + love.timer.getDelta()*0.25
                
                -- Draw concentric circles that get smaller
                local maxRadius = gravityWell.stats.range * 50 * (Player.currentCore == "Madness Core" and 2 or 1)
                local numCircles = 5
                for i = 1, numCircles do
                    local phase = (gravityWell.animTime * 0.5 + i/numCircles) % 1
                    local radius = maxRadius * (1 - phase)
                    love.graphics.setColor(gravityWell.color[1], gravityWell.color[2], gravityWell.color[3], phase)
                    love.graphics.circle("line", gravityWell.techTarget.x, gravityWell.techTarget.y, radius)
                end
                
                -- Draw target indicator
                love.graphics.setColor(gravityWell.color[1], gravityWell.color[2], gravityWell.color[3], 1)
                local size = 20
                love.graphics.line(
                    gravityWell.techTarget.x - size, gravityWell.techTarget.y,
                    gravityWell.techTarget.x + size, gravityWell.techTarget.y
                )
                love.graphics.line(
                    gravityWell.techTarget.x, gravityWell.techTarget.y - size,
                    gravityWell.techTarget.x, gravityWell.techTarget.y + size
                )
                
                -- Draw attraction lines from balls in range
                for _, ball in ipairs(Balls) do
                    local dx = gravityWell.techTarget.x - ball.x
                    local dy = gravityWell.techTarget.y - ball.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist <= gravityWell.stats.range * (Player.currentCore == "Madness Core" and 2 or 1) then
                        -- Draw fading line based on distance
                        local alpha = (1 - dist/(gravityWell.stats.range * (Player.currentCore == "Madness Core" and 2 or 1))) * 0.5
                        love.graphics.setColor(gravityWell.color[1], gravityWell.color[2], gravityWell.color[3], alpha)
                        love.graphics.line(ball.x, ball.y, gravityWell.techTarget.x, gravityWell.techTarget.y)
                    end
                end
            end
        end
    end]]
end

local function spellDraw()
    if not Player.levelingUp or Player.choosingUpgrade then
        ArcaneMissile.draw()
        FlameBurst.draw()
        for _, shadowBall in ipairs(shadowBalls) do
            drawShadowBall(shadowBall)
        end
    end
    if unlockedBallTypes["Light Beam"] then
        for _, lightbeam in ipairs(lightBeams) do
            love.graphics.setColor(1, 1, 1, lightbeam.opacity)
            local centerX = paddle.x + paddle.width/2
            centerX = centerX
            local centerY = paddle.y + paddle.height/2
            
            -- When lightBeamAngle is math.pi, cos will be -1, making the beam centered
            local x = centerX - math.cos(lightbeam.angle) * lightBeamImg:getWidth() * 0.125
            local y = centerY - math.sin(lightbeam.angle) * lightBeamImg:getWidth() * 0.125

            love.graphics.draw(lightBeamImg, x, y, lightbeam.angle, 0.25, 5)
        end
    end
end

function Balls:draw()
    -- Draw Flamethrower VFX first if active
    local flamethrower = unlockedBallTypes["Flamethrower"]

    -- Draw techs
    techDraw()
    
    -- Draw bullets
    drawBullets()

    -- drawSpells
    spellDraw()
    
    -- Draw balls
    for _, ball in ipairs(Balls) do
        if ball.type == "spell" then
            drawShadowBall(ball)
        else
            -- Draw the trail
            local ballColor = ballList[ball.name].color or {1,1,1,1}
            if ball.name == "Incrediball" then
                ballColor = incrediballColor
            end
            local sizeBoost = 1
            if not ball.dead and ball.name ~= "Phantom Ball" then
                local trail = ball.trail or {}
                local trailLen = #trail
                -- cheap offscreen cull (skip full trail draw if ball offscreen)
                local bx, by, br = ball.x, ball.y, ball.radius or 10
                if bx + br >= -64 and bx - br <= (screenWidth + 64) and by + br >= -64 and by - br <= (screenHeight + 64) and trailLen > 1 then
                    -- sample the trail to at most sampleMax segments (reduces draw calls)
                    local sampleMax = 8
                    local step = math.max(1, math.floor(trailLen / sampleMax))

                    -- cache locals for speed
                    local r, g, b = ballColor[1], ballColor[2], ballColor[3]
                    local invTrailLen = 1 / math.max(1, ballTrailLength)

                    -- cache ball radius and size calculations
                    local startRadius = math.max(1, (ball.radius or 10) * (ball.drawSizeBoost or 1))
                    local minRadius = startRadius * 0.15

                    -- Draw circles from oldest to newest for proper layering
                    for i = trailLen - 1, 1, -step do
                        local p = trail[i]
                        if p then
                            -- segment position (1 = near ball, 0 = tail)
                            local segmentPos = (i / math.max(1, trailLen))
                            local segmentPosSq = segmentPos * segmentPos

                            -- compute radius that tapers from ball radius -> small
                            local segRadius = minRadius + (startRadius - minRadius) * segmentPos
                            segRadius = segRadius * (ball.drawSizeMult or 1)

                            -- alpha that eases out towards tail with quadratic falloff
                            local alpha = math.max(0.04, segmentPosSq * (p.alpha or 1))
                            love.graphics.setColor(r, g, b, alpha)
                            love.graphics.circle("fill", p.x, p.y, segRadius)
                        end
                    end

                    love.graphics.setColor(1,1,1,1)
                end
            end

            if ball.name == "Phantom Ball" then
                local auraSize = getStat("Phantom Ball", "range") * 12
                -- Draw aura
                love.graphics.setColor(0, 0, 1, 1)
                drawImageCentered(auraImg, ball.x, ball.y, auraSize, auraSize)
                -- Make ball match the aura size
                love.graphics.setColor(0.25, 0.25, 1, 0.25)
                love.graphics.circle("fill", ball.x, ball.y, auraSize/2)
            else
                love.graphics.setColor(unlockedBallTypes[ball.name] and unlockedBallTypes[ball.name].color or {1, 1, 1, 1})
                if ball.name == "Incrediball" then
                    love.graphics.setColor(incrediballColor[1], incrediballColor[2], incrediballColor[3], incrediballColor[4])
                end
                love.graphics.circle("fill", ball.x, ball.y, (ball.radius or 10) * (ball.drawSizeBoost or 1) * sizeBoost * (ball.drawSizeMult or 1))
            end
        end
    end

    -- Draw arcane missiles
    for _, missile in ipairs(arcaneMissiles) do
        if missile.alive then
            love.graphics.setColor(0.3, 0.6, 1, 1)
            love.graphics.circle("fill", missile.x, missile.y, missile.radius * 0.5)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    if flamethrower and flamethrower.vfx and not (Player.levelingUp or Player.choosingUpgrade) then
        -- Save current blend mode
        local currentBlendMode = love.graphics.getBlendMode()
        
        -- Set additive blending with proper color
        --love.graphics.setBlendMode("add")
        love.graphics.setColor(1, 1, 1, 1)  -- Use white color for additive blending
        
        -- Draw the VFX
        
        flamethrower.vfx:render()
        
        -- Restore previous state
        love.graphics.setBlendMode(currentBlendMode)
        love.graphics.setColor(1, 1, 1, 1)
    end

    if not usingMoneySystem then

        -- draw powerups
        for _, powerup in ipairs(powerups) do
            -- draw trail from oldest -> newest using ring buffer
            local head = powerup._trailHead or 1
            local count = powerup._trailCount or 0
            if count > 0 then
                local startRadius = powerup.radius * 0.6
                local minRadius = math.max(1, startRadius * 0.15)
                for k = 0, count - 1 do
                    local idx = ((head + k - 1) % POWERUP_TRAIL_MAX) + 1
                    local p = powerup.trail[idx]
                    if p and p.alpha and p.alpha > 0 then
                        local t = (count > 1) and (k / (count - 1)) or 1
                        local alpha = p.alpha * (0.9 * t + 0.1)
                        local radius = minRadius + (startRadius - minRadius) * t
                        love.graphics.setColor(90/255, 150/255, 0.75, alpha)
                        love.graphics.circle("fill", p.x, p.y, radius)
                    end
                end
            end

            -- draw powerup image (always)
            love.graphics.setColor(1,1,1,1)
            local sizeMult = powerup.type == "dollarBill" and 0.8 or 1.3
            drawImageCentered(powerupImgs[powerup.type], powerup.x, powerup.y, 70 * sizeMult, 62 * sizeMult, powerup.angle)
        end
    end
end

return Balls
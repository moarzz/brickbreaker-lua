--This file holds the values for all the Balls in the game.
-- It also holds the functions for updating the Balls and drawing them.
local Smoke = require("particleSystems.smoke")
local Explosion = require("particleSystems.explosion")
local ArcaneMissile = require("particleSystems.arcaneMissile")
local FlameBurst = require("particleSystems.flameBurst")

startingBall = "Pistol" -- The first ball that is added to the game 
local Balls = {}
local ballCategories = {}
local ballList = {}
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

function Balls.amountIncrease()
    for _, ballType in pairs(unlockedBallTypes) do
        Balls.addBall(ballType.name)
    end
end

function Balls.getUnlockedBallTypes()
    return unlockedBallTypes
end

function Balls.clearUnlockedBallTypes()
    unlockedBallTypes = {}
end

brickPieces = {}
local function brickDestroyed(brick)
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
        local tween1 = tween.new(0.85, brickPiece1, {color = {0, 0, 0, 0}}, tween.outCubic)
        local tween2 = tween.new(0.85, brickPiece2, {color = {0, 0, 0, 0}}, tween.outCubic)
        local tween3 = tween.new(0.85, brickPiece3, {color = {0, 0, 0, 0}}, tween.outCubic)
        addTweenToUpdate(tween1)
        addTweenToUpdate(tween2)
        addTweenToUpdate(tween3)
        table.insert(brickPieces, brickPiece1)
        table.insert(brickPieces, brickPiece2)
        table.insert(brickPieces, brickPiece3)
end

local ballTrailLength = 80   -- Length of the ball trail
local bullets = {}
local deadBullets = {}
local laserBeamBrick
local laserBeamY = 0

local brickDeathSFXCd = 0
-- Update damage calculation in dealDamage function score
function dealDamage(ball, brick)
    local kill
    local damage = ball.stats.damage
    if ball.noReturn then
        damage = math.min(ball.stats.damage, brick.health)

        --deals damage to brick
        brick.health = brick.health - damage
        brick.color = getBrickColor(brick.health)

        damageNumber(damage, brick.x + brick.width / 2, brick.y + brick.height / 2, {1, 0, 0, 1}) -- Red color for normal damage

        damageThisFrame = damageThisFrame + damage -- Increase the damage dealt this frame

        -- brick hit vfx
        VFX.brickHit(brick, ball, damage)

        if brick.health >= 1 then
            brick.hitLastFrame = true
        else
            kill = true
            brickKilledThisFrame = true
            --[[if brickDeathSFXCd <= 0 then
                -- Only play sound effect if cooldown is not active
                playSoundEffect(brickDeathSFX, 0.4, 1, false, true)
                brickDeathSFXCd = 0.025 -- Set cooldown for damage visuals
            end]]
            brick.destroyed = true
            brick = nil
            if ball.type == "bullet" then
                ball.stats.damage = ball.stats.damage - damage
                if ball.stats.damage <= 0 then
                    kill = false
                end
            end
        end
        Player.score = Player.score + damage -- Increase player score based on damage dealt
    end
    if Player.bonuses.damage then
        damage = damage + Player.bonuses.damage + (Player.permanentUpgrades.damage or 0)
    end
    if Player.permanentUpgrades.damage then
        damage = damage + Player.permanentUpgrades.damage
    end
    if ball.name == "Gold Ball" then
        local goldEarned = damage * 10 -- Double the damage for goldBall
        Player.gain(goldEarned) -- Increase player money based on gold ball damage
        damageNumber(goldEarned, brick.x + brick.width / 2, brick.y + brick.height / 2, {1, 1, 0, 1}) -- Yellow color for goldBall
    end
    if Player.perks.multishot and (ball.type == "bullet" or ball.type == "gun") then
        damage = math.ceil(damage / 2.0)
    end
    if Player.perks.techSupremacy and ball.type == "tech" then
        damage = damage * 2
    end
    damage = math.min(damage, brick.health)
    if Player.perks.brickBreaker and brick.type == "small" then
        if math.random(1,100) < 5 then
            damage = brick.health
        end
    end
    --deals damage to brick
    print("dealt : ".. damage .. " to brick with health : " .. brick.health)
    brick.health = brick.health - damage
    brick.color = getBrickColor(brick.health)
    if ball.name ~= "Gold Ball" then
        damageNumber(damage, brick.x + brick.width / 2, brick.y + brick.height / 2, {1, 0, 0, 1}) -- Red color for normal damage
    end

    damageThisFrame = damageThisFrame + damage -- Increase the damage dealt this frame

    -- brick hit vfx
    VFX.brickHit(brick, ball, damage)

    if brick.health >= 1 then
        brick.hitLastFrame = true
    else
        kill = true
        brickKilledThisFrame = true
        --[[if brickDeathSFXCd <= 0 then
            -- Only play sound effect if cooldown is not active
            playSoundEffect(brickDeathSFX, 0.4, 1, false, true)
            brickDeathSFXCd = 0.025 -- Set cooldown for damage visuals
        end]]

        brick.destroyed = true
        if ball.type == "bullet" then
            ball.stats.damage = ball.stats.damage - damage
            if ball.stats.damage <= 0 then
                kill = false
                ball = nil
            end
        end
    end
    -- Increase player money based on damage dealt
    if ball then
        if ball.name ~= "Gold Ball" then
            Player.gain(damage)
        end
    end

    if kill == true then
        brickDestroyed(brick)
        brick = nil
    elseif brick then
        if brick.health <= 0 then
            brickDestroyed(brick)
            brick = nil
        end
    end
    return(kill)
end

-- Update bullet damage in shoot function
local function shoot(gunName)
    if unlockedBallTypes[gunName] then
        local bulletStormMult = Player.perks.bulletStorm and 2 or 1
        local gun = unlockedBallTypes[gunName]
        if gun.currentAmmo > 0 then
            for _, ballType in pairs(unlockedBallTypes) do
                if ballType.onShoot then
                    ballType.onShoot()
                end
            end
            playSoundEffect(gunShootSFX, 0.5, 1, false, true)
            local speedOffset = (paddle.currentSpeedX or 0) * 0.4
            local bulletDamage = gun.stats.damage + 
                (Player.bonuses.damage or 0) + 
                (Player.permanentUpgrades.damage or 0)
            local bulletSpeed = gun.bulletSpeed or 1000

            -- decrease ammo
            gun.currentAmmo = gun.currentAmmo - 1

            -- shoot function for each different gun and default
            if gun.name == "Shotgun" then
                for i = 1, 6 do
                    local speedXref = math.random(-125, 125) + speedOffset
                    table.insert(bullets, {
                        type = "bullet",
                        x = paddle.x + paddle.width / 2 + (speedXref-speedOffset)/125 * paddle.width / 3,
                        y = paddle.y,
                        speedX = speedXref + math.random(-90, 90),
                        speedY = -math.sqrt(bulletSpeed^2 - (speedXref + math.random(-80, 80))^2),
                        radius = 5,
                        stats = {damage = bulletDamage},
                        hasSplit = false,
                        hasTriggeredOnBulletHit = false,
                    })
                end
            elseif gun.name == "Sniper" then
                bulletDamage = (bulletDamage - (Player.perks.multishot and -3 or 0)) * 10
                local target = nil
                local maxHealth = -math.huge
                for _, enemy in ipairs(bricks) do
                    if not enemy.dead and enemy.health > maxHealth and enemy.y > -brickHeight then
                        maxHealth = enemy.health
                        target = enemy
                    end
                end
                if target then
                    local speedXref = (target.x + target.width / 2) - (paddle.x + paddle.width / 2)
                    local speedYref = (target.y + target.height / 2) - (paddle.y + paddle.height / 2)
                    local speedMagnitude = math.sqrt(speedXref^2 + speedYref^2)
                    if speedMagnitude > 0 then
                        speedXref = (speedXref / speedMagnitude) * bulletSpeed + speedOffset
                        speedYref = (speedYref / speedMagnitude) * bulletSpeed
                    else
                        speedXref = 0
                        speedYref = -bulletSpeed -- Default to straight up if no target found
                    end
                    table.insert(bullets, {
                        type = "bullet",
                        x = paddle.x + paddle.width / 2,
                        y = paddle.y,
                        speedX = speedXref,
                        speedY = speedYref,
                        radius = 5,
                        stats = {damage = bulletDamage},
                        hasSplit = false,
                        hasTriggeredOnBulletHit = false,
                    })
                end
            else -- default shooting behavior
                local speedXref = math.random(-100, 100) + speedOffset
                local xBruh = paddle.x + paddle.width / 2 +math.random(-100,100)/100 * paddle.width / 3
                table.insert(bullets, {
                    type = "bullet",
                    x = xBruh,
                    y = paddle.y,
                    speedX = speedXref,
                    speedY = -math.sqrt(bulletSpeed^2 - speedXref^2),
                    radius = 5,
                    stats = {damage = bulletDamage},
                    hasSplit = false,
                    hasTriggeredOnBulletHit = false,
                })
                local normalizedSpeedX, normalizedSpeedY = normalizeVector(speedXref, -math.sqrt(bulletSpeed^2 - speedXref^2))
                muzzleFlash(xBruh, paddle.y, -math.acos(normalizedSpeedX))
            end
            if gun.name == "Minigun" then
                Timer.after((2.0*mapRangeClamped(gun.stats.ammo - gun.currentAmmo,0,50, 5,0.6))/((gun.stats.fireRate + (Player.bonuses.fireRate or 0)) * bulletStormMult), function() shoot(gunName) end)
            else
                Timer.after(2.0/((gun.stats.fireRate + (Player.bonuses.fireRate or 0)) * bulletStormMult), function() shoot(gunName) end)
            end
        else
            gun.currentAmmo = gun.stats.ammo + 
                (Player.bonuses.ammo or 0) + 
                (Player.permanentUpgrades.ammo or 0) -- Reset ammo using the stats value
            if gun.name == "Minigun" then
                Timer.after((gun.stats.cooldown + (Player.bonuses.cooldown or 0)) * 2, function() shoot(gunName) end)
                --cooldownVFX(gun.stats.cooldown * 2, paddle.x + paddle.width / 2, paddle.y)
            else
                Timer.after(gun.stats.cooldown + (Player.bonuses.cooldown or 0), function() shoot(gunName) end)
                --cooldownVFX(gun.stats.cooldown * 2, paddle.x + paddle.width / 2, paddle.y)
            end
        end
    else 
        print("Error: gun is not unlocked but shoot is being called.")
    end
end

local laserBeamTarget = nil
local laserBeamTimer = 0
local laserAlpha = {a = 0}
local function fire(techName)    
    if techName == "Atomic Bomb" then
        for _, brick in ipairs(bricks) do
            print("brick health : " .. brick.health .. " - brick.y : " .. brick.y .. "brick.height : " .. brick.height)
            if (brick.health > 0 )and (brick.y + brick.height > 0) then
                dealDamage(unlockedBallTypes["Atomic Bomb"], brick) -- Deal damage to all bricks
            end
        end
    end
    if techName == "Laser" then
        unlockedBallTypes["Laser"].currentChargeTime = 0
        laserAlpha.a = 1
        local laserTween = tween.new(0.5, laserAlpha, {a = 0}, tween.inQuad)
        addTweenToUpdate(laserTween)
        for _, brick in ipairs(bricks) do
            if not brick.destroyed and brick.y > -brick.height then
                if paddle.x < brick.x + brick.width and paddle.x + paddle.width > brick.x then
                    dealDamage({stats = {damage = unlockedBallTypes["Laser"].stats.damage}, speedX = 0, speedY = -1}, brick)
                end
            end
        end
        unlockedBallTypes["Laser"].charging = true
    end
end

-- Table to hold active arcane missiles
local arcaneMissiles = {}
local fireballs = {}
local darts = {}

local function cast(spellName, brick)
    if spellName == "Thundershock" then
        local lowestHealthBrick = nil
        for _, brick in ipairs(bricks) do
            if not brick.dead and (not lowestHealthBrick or brick.health < lowestHealthBrick.health) and brick.health > 0 and brick.y + brick.height > 0 then
                lowestHealthBrick = brick
            end
        end
        if lowestHealthBrick then
            local damage = unlockedBallTypes["Thundershock"].stats.damage + (Player.bonuses.damage or 0) + (Player.permanentUpgrades.damage or 0)
            createSpriteAnimation(lowestHealthBrick.x + lowestHealthBrick.width / 2, lowestHealthBrick.y + lowestHealthBrick.height / 2, 2, sparkVFX, 32, 32, 0.05, 0)
            Timer.after(0.15, function()
                dealDamage(unlockedBallTypes["Thundershock"], lowestHealthBrick)
            end)
        end
    end
    if spellName == "Fireball" then
        local angle = (math.random() * 0.3 + 0.35) * math.pi
        local speed = 500 + ((Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0))*50
        local range = (unlockedBallTypes["Fireball"].stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0))
        local fireball = {
            x = paddle.x + paddle.width / 2,
            y = paddle.y,
            speedX = speed * math.cos(angle),
            speedY = -speed * math.sin(angle),
            radius = 10 * range,
            stats = unlockedBallTypes["Fireball"].stats,
            damage = unlockedBallTypes["Fireball"].stats.damage + (Player.bonuses.damage or 0) + (Player.permanentUpgrades.damage or 0),
            range = range,
            trail = {},
            dead = false
        }
        table.insert(fireballs, fireball)
    end
    if spellName == "Arcane Missiles" then
        -- Per-ball cooldown: only allow cast once per 2 seconds per ball
        if not unlockedBallTypes["Arcane Missiles"].lastCast or love.timer.getTime() - (unlockedBallTypes["Arcane Missiles"].lastCast or 0) >= 0.025 then
            unlockedBallTypes["Arcane Missiles"].lastCast = love.timer.getTime()
            for i = 1, unlockedBallTypes["Arcane Missiles"].stats.amount + (Player.bonuses.amount or 0) + (Player.permanentUpgrades.amount or 0) do
                Timer.after((i-1) * 0.1, function()
                    -- Pick a random valid brick at cast time
                    local validBricks = {}
                    for _, brick in ipairs(bricks) do
                        if not brick.destroyed and brick.health > 0 and brick.y > -brick.height then
                            table.insert(validBricks, brick)
                        end
                    end
                    local targetBrick = nil
                    if #validBricks > 0 then
                        targetBrick = validBricks[math.random(1, #validBricks)]
                    end
                    local angle = (math.random() * 0.5 - 0.75) * math.pi
                    local missileSpeed = 2000
                    local startX = paddle.x + paddle.width/2
                    local startY = paddle.y
                    local vx = math.cos(angle) * missileSpeed
                    local vy = math.sin(angle) * missileSpeed
                    table.insert(arcaneMissiles, {
                        x = startX,
                        y = startY,
                        vx = vx,
                        vy = vy,
                        radius = 8,
                        damage = (unlockedBallTypes["Arcane Missiles"].stats.damage or 1) + (Player.bonuses.damage or 0) + (Player.permanentUpgrades.damage or 0),
                        alive = true,
                        target = targetBrick
                    })
                end)
            end
        end
    end
    if spellName == "Flame Burst" then
        local spell = unlockedBallTypes["Flame Burst"]
        spell.lastCast = 0
        -- Emit the flame burst effect from the paddle
        local damage = spell.stats.damage + (Player.bonuses.damage or 0) + (Player.permanentUpgrades.damage or 0)
        local range = (spell.stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0)) * 50
        FlameBurst.emit(paddle.x + paddle.width/2, paddle.y, damage, range*0.8)
    end
    if spellName == "Poison Dart" then
        print("Poison Dart")
        local speed = 500
        local angle = math.rad((math.random() * 0.04 + 0.48) * 180)
        local dart = {
            x = paddle.x + paddle.width / 2,
            y = paddle.y,
            speedX = speed * math.cos(angle),
            speedY = -speed * math.sin(angle),
            radius = 10,
            trail = {},
            dead = false
        }
        table.insert(darts, dart)
    end
    if spellName == "Lightning Strike" then
        print("Casting Lightning Strike")
        for i=1, unlockedBallTypes["Lightning Strike"].stats.amount + (Player.bonuses.amount or 0) + (Player.permanentUpgrades.amount or 0) do
            local range = (unlockedBallTypes["Lightning Strike"].stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0)) * 50
            local positionX, positionY = math.random(statsWidth + range/2, screenWidth - statsWidth - range/2), math.random(range/2, screenHeight - range/2)
            local scale = range / 32
            createSpriteAnimation(positionX, positionY, scale, lightningVFX, 32, 32, 0.025, 0)
            Timer.after(0.1, function()
                local touchingBricks = getBricksTouchingCircle(positionX, positionY, range/2)
                for _, brick in ipairs(touchingBricks) do
                    if not brick.destroyed and brick.health > 0 and brick.y > -brick.height then
                        dealDamage(unlockedBallTypes["Lightning Strike"], brick)
                    end
                end
            end)
        end
        local timeUntilNextCast = math.max(unlockedBallTypes["Lightning Strike"].stats.cooldown + (Player.bonuses.cooldown or 0) + (Player.permanentUpgrades.cooldown or 0), 1)/3
        print("Next Lightning Strike in: " .. timeUntilNextCast .. " seconds")
        Timer.after(timeUntilNextCast, function()
            cast("Lightning Strike")
        end)
    end
    if spellName == "Chain Lightning" then
        print("Casting Chain Lightning")
        -- Per-brick cooldown table for Chain Lightning
        if not unlockedBallTypes["Chain Lightning"].chainCooldowns then
            unlockedBallTypes["Chain Lightning"].chainCooldowns = {}
        end
        local chainCooldowns = unlockedBallTypes["Chain Lightning"].chainCooldowns
        local chainLength = unlockedBallTypes["Chain Lightning"].stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0)
        local function chainStep(currentBrick, step)
            if step > chainLength or not currentBrick then return end
            local now = love.timer.getTime()
            -- Only allow if cooldown expired
            if not chainCooldowns[currentBrick] or now - chainCooldowns[currentBrick] >= 1 then
                chainCooldowns[currentBrick] = now
                local currentX, currentY = currentBrick.x, currentBrick.y
                local touchingBricks = getBricksTouchingCircle(currentX, currentY, 100)
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
                        createSpriteAnimation(spawnX, spawnY, 1, chainLightningVFX, 256, 128, 0.075, 0, false, scaleX, scaleX*1.5, angle)
                        Timer.after(0.3, function()
                            dealDamage(unlockedBallTypes["Chain Lightning"], targetBrick)
                            chainStep(targetBrick, step + 1)
                        end)
                    end
                end
            else
                print("Chain Lightning on brick is on cooldown.")
            end
        end
        chainStep(brick, 1)
    end
end

--list of all ball types in the game
local function ballListInit()
    ballList = {
        ["Ball"] = {
            name = "Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            startingPrice = 5,
            rarity = "common",
            description = "The most basic ball, it has no special abilities.",
            color = {1, 1, 1, 1}, -- White color
            stats = {
                speed = 250,
                damage = 1,
            },
        },
        ["Ping-Pong ball"] = {
            name = "Ping-Pong ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 15,
            description = "A bouncy ball affected by gravity. Builds up speed as it falls!",
            color = {0.95, 0.95, 0.85, 1}, -- Off-white color like a real ping pong ball
            stats = {
                speed = 400,
                damage = 1,
            },
        },
        ["Exploding Ball"] = {
            name = "Exploding Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 20,
            description = "A ball that explodes on impact, dealing damage to nearby bricks.",
            color = {1, 0, 0, 1}, -- Red color
            stats = {
                speed = 100,
                damage = 2,
                range = 2
            },
        },
        ["Phantom Ball"] = {
            name = "Phantom Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 2,
            rarity = "rare",
            startingPrice = 20,
            description = "A ball that can pass through bricks.",
            color = {0.5, 0.5, 0.7, 0.6}, -- Blue color
            stats = {
                speed = 50,
                damage = 1,
                range = 1
            },
        },
        ["Gold Ball"] = {
            name = "Gold Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 10,
            description = "Hits brick : gain money equal to 10 * DMG. Deals no damage",
            color = {1, 0.84, 0, 1},
            stats = {
                speed = 150,
                damage = 2,
            },
        },
         ["Magnetic Ball"] = {
            name = "Magnetic Ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "rare",
            startingPrice = 50,
            description = "A ball that's magnetically attracted to the nearest brick",
            color = {0.6, 0.2, 0.8, 1}, -- Purple color
            stats = {
                speed = 100,
                damage = 1,
            },
            attractionStrength = 2500
        },
        ["Pistol"] = {
            name = "Pistol",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "common",
            startingPrice = 5,
            description = "fire bullets that die on impact",
            onBuy = function() 
                shoot("Pistol")
            end,
            noAmount = true,
            currentAmmo = 10 + (Player.bonuses.ammo or 0),
            bulletSpeed = 1000,

            stats = {
                damage = 1,
                cooldown = 6,
                ammo = 10,
                fireRate = 5,
            },
        },
        ["Machine Gun"] = {
            name = "Machine Gun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 10,
            description = "fire bullets that die on impact in bursts",
            onBuy = function() 
                shoot("Machine Gun")
            end,
            noAmount = true,
            currentAmmo = 12 + (Player.bonuses.ammo or 0),
            bulletSpeed = 1000,

            stats = {
                damage = 1,
                cooldown = 8,
                ammo = 15,
                fireRate = 10,
            },
        },
        Shotgun = {
            name = "Shotgun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 10,
            description = "fire bullets that die on impact in bursts",
            onBuy = function() 
                shoot("Shotgun")
            end,
            noAmount = true,
            currentAmmo = 2 + (Player.bonuses.ammo or 0),
            bulletSpeed = 750,

            stats = {
                damage = 1,
                cooldown = 12,
                ammo = 2,
                fireRate = 1,
            },
        },
        Sniper = {
            name = "Sniper",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 20,
            description = "always fires bullet towards one of the highest health enemies. this has 10x damage",
            onBuy = function() 
                shoot("Sniper")
            end,
            noAmount = true,
            currentAmmo = 1 + (Player.bonuses.ammo or 0),
            bulletSpeed = 1500,

            stats = {
                damage = 1,
                cooldown = 8,
                ammo = 1,
                fireRate = 1,
            },
        },
        Minigun = {
            name = "Minigun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "rare",
            startingPrice = 50,
            description = "Fires bullets at an accelerating rate of fire, reload time is doubled",
            onBuy = function() 
                shoot("Minigun")
            end,
            noAmount = true,
            currentAmmo = 100 + (Player.bonuses.ammo or 0) + (Player.permanentUpgrades.ammo or 0),
            bulletSpeed = 1500,

            stats = {
                damage = 1,
                cooldown = 10,
                ammo = 80,
                fireRate = 15,
            },
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
            rarity = "rare",
            startingPrice = 20,
            description = "Paddle shoots Laser Beam forward equal to it's width that goes through bricks with a slow cooldown." .. 
            "\n\n when a ball bounces off the paddle, the laser's cooldown is charged by 1 second",
            color = {0, 1, 0, 1}, -- Green color
            stats = {
                damage = 1,
                cooldown = 10,
            },
        },
        ["Laser Beam"] = {
            name = "Laser Beam",
            type = "tech",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "rare",
            startingPrice = 5,
            description = "Fire a thin Laser Beam beam that stops at the first brick hit. Fast fire rate but lower damage.",
            color = {1, 0, 0, 1}, -- Red color for Laser Beam
            currentAmmo = 10 + (Player.bonuses.ammo or 0),
            stats = {
                damage = 1,
                fireRate = 1
            },
        },
        ["Atomic Bomb"] = {
            name = "Atomic Bomb",
            type = "tech",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "legendary",
            startingPrice = 1000,
            description = "A powerful bomb that deals massive damage to all bricks on the screen.",
            color = {1, 0.5, 0, 1}, -- Orange color for Atomic Bomb
            onBuy = function()
                fire("Atomic Bomb")
            end,
            stats = {
                damage = 1000,
                cooldown = 60,
            },
        },
        ["Gravity pulse"] = {
            name = "Gravity pulse",
            type = "tech",
            size = 1,
            noAmount = true,
            rarity = "rare",
            startingPrice = 50,
            description = "Creates an attraction point at nearest brick that pulls balls towards it and increases their damage. Attraction force scales with ball speed",
            color = {0.1, 0.1, 0.3, 1}, -- Dark blue color theme
            canBuy = function()
                for _, ballType in pairs(unlockedBallTypes) do
                    if ballType.type == "ball" then
                        return true -- Flame Burst can be unlocked
                    end
                end
                return false
            end,
            stats = {
                damage = 2,
                range = 2, -- Added range stat for Gravity pulse area of effect
            },
            attractionStrength = 250,
        },
        ["Saw Blades"] = {
            name = "Saw Blades",
            type = "tech",
            size = 1,
            noAmount = true,
            rarity = "uncommon",
            startingPrice = 50,
            description = "Creates deadly Saw Blades that orbit around your paddle, damaging any bricks they touch",
            color = {0.7, 0.7, 0.7, 1}, -- Grey color theme
            stats = {
                damage = 1,
                amount = 1, -- Number of saws
                speed = 150, -- Rotations per second
            },
            sawPositions = {}, -- Will store current positions of saws
            sawAnimations = {}, -- Will store animation IDs
            currentAngle = 0, -- Current rotation angle
            orbitRadius = 250,
            damageCooldowns = {}, -- Add this line to track cooldowns per saw per brick
        },
        ["Thundershock"] = {
            name = "Thundershock",
            type = "tech",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "uncommon",
            startingPrice = 50,
            description = "when a brick is destroyed, deal damage to the lowest health brick",
            color = {0.5, 0.5, 1, 1}, -- Blue color for Thundershock
            onBrickDestroyed = function() 
                cast("Thundershock")
            end,
            stats = {
                damage = 2,
            },
        },
        ["Fireball"] = {
            name = "Fireball",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "uncommon",
            startingPrice = 100,
            description = "On paddle Bounces, fire a fireball at a random angle that explodes on impact.",
            color = {1, 0.5, 0, 1}, -- Orange color for Fireball
            counter = 0,
            onPaddleBounce = function()
                cast("Fireball")
            end,
            canBuy = function()
                for _, ballType in pairs(unlockedBallTypes) do
                    if ballType.type == "ball" then
                        return true -- Fireball can be unlocked
                    end
                end
                return false
            end,
            stats = {
                damage = 3,
                range = 2,
                cd = 5
            }
        },
        ["Arcane Missiles"] = {
            name = "Arcane Missiles",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "rare",
            startingPrice = 500,
            description = "on brickBounce, shoot missiles at the nearest brick",
            color = {0.5, 0, 0.5, 1}, -- Purple color for Arcane Missile
            canBuy = function()
                for _, ballType in pairs(unlockedBallTypes) do
                    if ballType.type == "ball" then
                        return true -- Flame Burst can be unlocked
                    end
                end
                return false
            end,
            onBrickBounce = function()
                cast("Arcane Missiles")
            end,
            stats = {
                amount = 1,
                damage = 1,
            },
        },
        ["Flame Burst"] = {
            name = "Flame Burst",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "rare",
            startingPrice = 100,
            description = "on shoot, emits a fiery pulse from the paddle that damages all bricks in its radius.",
            color = {1, 0.4, 0, 1},
            cooldown = 2.0,
            lastCast = 0,
            canBuy = function()
                for _, ballType in pairs(unlockedBallTypes) do
                    if ballType.type == "gun" then
                        return true -- Flame Burst can be unlocked
                    end
                end
                return false
            end,
            onShoot = function()
                cast("Flame Burst")
            end,
            stats = {
                damage = 2,
                range = 4
            },
        },
        --[["Poison Dart"] = {
            name = "Poison Dart",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "rare",
            startingPrice = 500,
            description = "on wallBounce, fires a dart that creates a poison cloud. Damaging bricks every second.",
            color = {0.2, 0.8, 0.2, 1},
            onWallBounce = function()
                cast("Poison Dart")
            end,
            stats = {
                damage = 1,
                range = 3,
                fireRate = 3,
            },
        },]]
        ["Lightning Strike"] = {
            name = "Lightning Strike",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "legendary",
            startingPrice = 100,
            description = "every [cooldown] seconds, strike a random brick with lightning, dealing massive damage.",
            color = {0.8, 0.8, 0.2, 1},
            onBuy = function()
                cast("Lightning Strike")
            end,
            stats = {
                cooldown = 8,
                damage = 5,
                range = 3,
                amount = 1, -- Amount of lightning strikes
            },
        },
        ["Chain Lightning"] = {
            name = "Chain Lightning",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "legendary",
            startingPrice = 500,
            description = "on bullet first hit, start a lightning chain that bounces between nearby bricks.",
            color = {0.5, 0.5, 1, 1},
            onBulletHit = function(brick)
                cast("Chain Lightning", brick)
            end,
            stats = {
                damage = 1,
                range = 1
            },
        },

    }
    for _, ball in pairs(ballList) do
        ball.radius = ball.size*10 -- Set the radius based on size
    end
    print("Ball list initialized with " .. #ballList .. " ball types.")
end

-- calls ballListInit and adds a ball to i
function Balls.initialize()
    ballCategories = {}
    ballList = {}   
    unlockedBallTypes = {}
    ballListInit()
    --Balls.addBall("Gold Ball") -- Add Saw Blades as a starting ball
end

function Balls.addBall(ballName, singleBall)
    singleBall = singleBall or false -- If singleBall is not provided, default to false
    ballName = ballName or "Ball" -- Default to baseBall if no name is provided
    print("Adding ball: " .. ballName)

    -- Check if ball type is already unlocked
    local isNewBall = not unlockedBallTypes[ballName]

    local stats = nil
    local ballTemplate = ballList[ballName]
    if ballTemplate then -- makes sure there is a ball with ballName in ballList
        print("isNewBall: " .. tostring(isNewBall))
        if isNewBall then
            local newBallType = {
                name = ballName, -- Set the name of the ball
                type = ballTemplate.type,
                amount = 1, -- Set the initial amount to 1
                noAmount = ballTemplate.noAmount or false, -- Set noAmount to false if not specified
                charging = true,
                currentChargeTime = 0,
                color = ballTemplate.color or {1, 1, 1, 1}, -- Set the color of the ball
                price = ballTemplate.startingPrice, -- Set the initial price of ball upgrades
                currentAmmo = ((ballTemplate.currentAmmo or 0) + (Player.bonuses.ammo or 0)), -- Copy specific values from the template
                bulletSpeed = ballTemplate.bulletSpeed or 1000, -- Set the bullet speed if it exists
                attractionStrength = ballTemplate.attractionStrength or nil, -- Set the attraction strength if it exists
                currentAngle = ballTemplate.currentAngle or nil,
                orbitRadius = ballTemplate.orbitRadius or nil,
                counter = ballTemplate.counter or nil,
                onBrickBounce = ballTemplate.onBrickBounce or nil,
                onBrickDestroyed = ballTemplate.onBrickDestroyed or nil,
                onWallBounce = ballTemplate.onWallBounce or nil,
                onShoot = ballTemplate.onShoot or nil,
                onPaddleBounce = ballTemplate.onPaddleBounce or nil,
                onBulletHit = ballTemplate.onBulletHit or nil,
                onBuy = ballTemplate.onBuy or nil, -- Function to call when the ball is
                canBuy = ballTemplate.canBuy or true, -- Function to check if the ball can be bought
                stats = {} -- Set the initial cooldown
            }
            for statName, statValue in pairs(ballTemplate.stats) do
                newBallType.stats[statName] = statValue -- Copy other stats as well
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
            local loops = singleBall and 1 or ((Player.bonuses.amount or 0) + (Player.permanentUpgrades.amount or 0) + 1)
            for i=1, loops do
                local totalSpeed = (ballTemplate.stats.speed or 0) + ((Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0))*50
                local speedX = math.random(-totalSpeed*0.6, totalSpeed*0.6)
                local speedY = -math.sqrt(math.max(0.01, totalSpeed^2 - speedX^2))
                local newBall = {
                    type = "ball",
                    name = ballTemplate.name,
                    x = ballTemplate.x,
                    y = math.max(getHighestBrickY() + ballTemplate.radius + 10, screenHeight/4),
                    radius = ballTemplate.radius * 1.25,
                    drawSizeBoost = 1,
                    drawSizeBoostTweens = {},
                    currentlyOverlappingBricks = {},
                    attractionStrength = ballTemplate.attractionStrength or nil,
                    stats = stats,
                    speedX = speedX,
                    speedY = speedY,
                    dead = false,
                    trail = {},
                    speedMultiplier = 1
                }
                table.insert(Balls, newBall)
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
            local totalSpeed = ball.stats.speed + ((Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0))*50
            ball.speedX = totalSpeed * normalisedSpeedX
            ball.speedY = totalSpeed * normalisedSpeedY
            print("new ball speed : " .. ball.speedX .. ", " .. ball.speedY)
        end
    end
end

function ballHitVFX(ball)
    for _, tweenID in ipairs(ball.drawSizeBoostTweens) do
        removeTween(tweenID) -- Remove the previous tween if it exists
    end
    ball.drawSizeBoostTweens = {} -- Clear the previous tweens
    local hitTween = tween.new(0.05, ball, {drawSizeBoost = math.min(ball.drawSizeBoost+1, 5)}, tween.outQuad)
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
    if ball.name == "Exploding Ball" then
        -- Create explosion using new particle system
        local scale = (ball.stats.range + (Player.bonuses.range or 0)) * 0.75
        -- Limit Chain Lightning sprite animations to 25 at once
        createSpriteAnimation(ball.x, ball.y, scale/3, explosionVFX, 512, 512, 0.02, 5)

        --Explosion.spawn(ball.x, ball.y, scale)
        
        -- Play explosion sound
        playSoundEffect(explosionSFX, 0.3 + scale * 0.2, math.max(1 - scale * 0.1, 0.1), false, true)
        
        dealDamage(ball, brick)
        local bricksTouchingCircle = getBricksTouchingCircle(ball.x, ball.y, (ball.stats.range + (Player.bonuses.range or 0)) * 24)
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
        if ballType.onBrickBounce then
            ballType.onBrickBounce() -- Call the onBrickBounce function if it exists
        end
    end
end

local function brickCollisionCheck(ball, bricks, Player)
    local hitAnyBrick = false

    -- Special handling for phantom ball - needs to check ALL bricks
    if ball.name == "Phantom Ball" or ball.name == "Damage boost ball" then
        -- First, create a table to track bricks we're currently overlapping with
        local currentlyOverlappingBricks = {}

        for index, brick in ipairs(bricks) do
            if not brick.destroyed then
                local wasOverlaping = ball.currentlyOverlappingBricks[index] or false
                local range = ball.stats.range + (Player.bonuses.range or 0)
                if wasOverlaping == true then
                    if not (ball.x + ball.radius * range > brick.x and ball.x - ball.radius * range < brick.x + brick.width and
                    ball.y + ball.radius * range > brick.y and ball.y - ball.radius * range < brick.y + brick.height) then
                        ball.currentlyOverlappingBricks[index] = nil -- Remove from currently overlapping if not overlapping anymore
                    end
                else
                    -- Check if we're currently overlapping with this brick
                    if ball.x + ball.radius * range > brick.x and ball.x - ball.radius * range < brick.x + brick.width and
                    ball.y + ball.radius * range > brick.y and ball.y - ball.radius * range < brick.y + brick.height then
                        ball.currentlyOverlappingBricks[index] = true
                        if ball.name == "Phantom Ball" then
                            dealDamage(ball, brick) -- Deal damage for new overlaps
                            -- If this brick wasn't in our last frame overlaps, it's a new entry
                            hitAnyBrick = true
                        end
                    end
                end
            end
        end
        if ball.name == "Phantom Ball" then
            return hitAnyBrick
        end
    end
    
    -- Regular ball collision logic
    for index, brick in ipairs(bricks) do
        if brick.hitLastFrame then
            brick.hitLastFrame = false
        elseif not brick.destroyed then
            if ball.x + ball.radius > brick.x and ball.x - ball.radius < brick.x + brick.width and
               ball.y + ball.radius > brick.y and ball.y - ball.radius < brick.y + brick.height then
                local overlapX = math.min(ball.x + ball.radius - brick.x, brick.x + brick.width - ball.x + ball.radius)
                local overlapY = math.min(ball.y + ball.radius - brick.y, brick.y + brick.height - ball.y + ball.radius)
                if Player.perks.speedBounce then
                    ball.speedExtra = (ball.speedExtra or 1) + 5
                end

                brickCollisionEffects(ball, brick)

                if overlapX < overlapY then
                    ball.speedX = -ball.speedX
                    if ball.x < brick.x + brick.width / 2 then
                        ball.x = ball.x - overlapX
                    else
                        ball.x = ball.x + overlapX
                    end
                else
                    ball.speedY = -ball.speedY
                    if ball.y < brick.y + brick.height / 2 then
                        ball.y = ball.y - overlapY
                    else
                        ball.y = ball.y + overlapY
                    end
                end
                if ball.name == "Ping-Pong ball" and ball.speedY < 0 then
                    ball.speedY = ball.speedY - 150 -- Increase speedY for Ping-Pong ball
                end
                if ball.name == "Magnetic Ball" then
                    local normalizedSpeedX, normalizedSpeedY = normalizeVector(ball.x - (brick.x + brick.width/2), ball.y - (brick.y + brick.height/2))
                    ball.speedX = ball.speedX + normalizedSpeedX * 250
                    ball.speedY = ball.speedY + normalizedSpeedY * 250
                end
                return true
            end
        end
    end
    return false
end

local function paddleCollisionCheck(ball, paddle)
    if ball.x + ball.radius > paddle.x and ball.x - ball.radius < paddle.x + paddle.width and ball.speedY > 0 and
       ball.y + ball.radius > paddle.y and ball.y - ball.radius < paddle.y + paddle.height and ball.speedY >= 0 then
        playSoundEffect(paddleBoopSFX, 0.6, 1, false, true)
        ball.speedY = -ball.speedY
        local hitPosition = (ball.x - (paddle.x - ball.radius)) / (paddle.width + ball.radius * 2)
        local ballSpeed = ball.stats.speed + ((Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0)) * 50
        ball.speedX = (hitPosition - 0.5) * 2 * math.abs(ballSpeed * 0.99)
        ball.speedY = math.sqrt(ballSpeed^2 - ball.speedX^2) * (ball.speedY > 0 and 1 or -1)
        if Player.perks.speedBounce then
            ball.speedExtra = (ball.speedExtra or 1) + 5
        end
        if unlockedBallTypes["Laser"] then
            unlockedBallTypes["Laser"].currentChargeTime = unlockedBallTypes["Laser"].currentChargeTime + 1 -- Reset charge time
            if Player.perks.paddleSquared then
                unlockedBallTypes["Laser"].currentChargeTime = unlockedBallTypes["Laser"].currentChargeTime + 1 -- Reset charge time
            end
        end
        for _, ballType in pairs(unlockedBallTypes) do
            if ballType.onPaddleBounce then
                ballType.onPaddleBounce() -- Call the onPaddleBounce function if it exists
                if Player.perks.paddleSquared then
                    ballType.onPaddleBounce()
                end
            end
        end
        if ball.name == "Ping-Pong ball" then
            ball.speedY = ball.speedY - 150 -- Increase speedY for Ping-Pong ball
        end
        return true
    end
    return false
end

local function wallCollisionCheck(ball)
    local wallHit = false
    if ball.x - ball.radius < statsWidth and ball.speedX < 0 then
        ball.speedX = -ball.speedX
        ball.x = statsWidth + ball.radius -- Ensure the ball is not stuck in the wall
        if Player.perks.speedBounce then
            ball.speedExtra = (ball.speedExtra or 1) + 5
        end
        if ball.y < screenWidth then
            playSoundEffect(wallBoopSFX, 0.5, 0.5)
        end
        wallHit = true
    elseif ball.x + ball.radius > screenWidth - statsWidth and ball.speedX > 0 then
        ball.speedX = -ball.speedX
        ball.x = screenWidth - statsWidth - ball.radius -- Ensure the ball is not stuck in the wall
        if Player.perks.speedBounce then
            ball.speedExtra = (ball.speedExtra or 1) + 5
        end
        if ball.y < screenWidth then
            playSoundEffect(wallBoopSFX, 1, 0.5)
        end
        wallHit = true
    end
    if ball.y - ball.radius < 0 and ball.speedY < 0 then
        ball.speedY = -ball.speedY
        ball.y = ball.radius -- Ensure the ball is not stuck in the wall
        if Player.perks.speedBounce then
            ball.speedExtra = (ball.speedExtra or 1) + 5
        end
        playSoundEffect(wallBoopSFX, 1, 0.5)
        wallHit = true
    elseif ball.y + ball.radius > screenHeight and ball.speedY > 0 then
        ball.speedY = -ball.speedY
        ball.y = screenHeight - ball.radius
        if Player.perks.speedBounce then
            ball.speedExtra = (ball.speedExtra or 1) + 5
        end
        playSoundEffect(wallBoopSFX, 1, 0.5)
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
    end
end

local function techUpdate(dt)
    if unlockedBallTypes["Laser"] then
        if unlockedBallTypes["Laser"].charging then
            unlockedBallTypes["Laser"].currentChargeTime = unlockedBallTypes["Laser"].currentChargeTime + dt
            if unlockedBallTypes["Laser"].currentChargeTime >= unlockedBallTypes["Laser"].stats.cooldown then
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
            if laserBeamTimer >= 1.0/laserBeam.stats.fireRate then
                dealDamage(laserBeam, laserBeamBrick)
                laserBeamTimer = 0  -- Reset timer after damage
            end
        else
            -- New target or no target, reset timer
            laserBeamTarget = laserBeamBrick
            laserBeamTimer = math.max(laserBeamTimer - dt * 2, 0) -- Decrease timer if not on target
        end
        laserBeamBrick = nil
        local highestY = -math.huge
        local highestBrick
        for _, brick in ipairs(bricks) do
            if brick.health > 0 and not brick.destroyed and -- Add these checks
               brick.y + brick.height > 0 and brick.y > highestY and 
               (paddle.x + paddle.width/2 - 1 >= brick.x and paddle.x + paddle.width/2 + 1 <= brick.x + brick.width) then
                highestY = brick.y + brick.height
                highestBrick = brick
            end
        end
        laserBeamBrick = highestBrick
        laserBeamY = highestY
    end

    if unlockedBallTypes["Gravity pulse"] then
        local gravityWell = unlockedBallTypes["Gravity pulse"]
        
        -- Find nearest brick in front of paddle
        local paddleX = paddle.x + paddle.width/2
        local paddleY = paddle.y
        local nearestBrick = nil
        local minDist = math.huge
        
        local highestY = -math.huge
        for _, brick in ipairs(bricks) do
            if brick.health > 0 and not brick.destroyed and
               brick.y + brick.height > 0 and brick.y > highestY and 
               (paddle.x + paddle.width/2 - 1 >= brick.x and paddle.x + paddle.width/2 + 1 <= brick.x + brick.width) then
                highestY = brick.y + brick.height
                nearestBrick = brick
            end
        end
        
        if nearestBrick then
            local targetX = nearestBrick.x + nearestBrick.width/2
            local targetY = nearestBrick.y + nearestBrick.height/2
            
            -- Store target for drawing
            gravityWell.techTarget = {x = targetX, y = targetY}
            
            -- Attract and boost damage of balls in range
            for _, ball in ipairs(Balls) do
                local dx = targetX - ball.x
                local dy = targetY - ball.y
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist <= gravityWell.stats.range*50 then
                    -- Store original speed if we haven't already
                    local attraction = gravityWell.attractionStrength * ball.stats.speed / math.max(dist, 10)
                    local angle = math.atan2(dy, dx)
                    
                    -- Update ball velocity
                    if ball.speedX and ball.speedY then
                        ball.speedX = ball.speedX + math.cos(angle) * attraction * dt
                        ball.speedY = ball.speedY + math.sin(angle) * attraction * dt
                        
                        -- Normalize velocity to maintain ball speed
                        local speed = math.sqrt(ball.speedX * ball.speedX + ball.speedY * ball.speedY)
                        local originalSpeed = ball.stats.speed + (Player.bonuses.speed or 0)
                        if speed > originalSpeed then
                            local scale = originalSpeed / speed
                            ball.speedX = ball.speedX * scale
                            ball.speedY = ball.speedY * scale
                        end
                    end
                    
                    ball.damageMultiplier = gravityWell.stats.damage
                else
                    local currentSpeed = math.sqrt(ball.speedX * ball.speedX + ball.speedY * ball.speedY)
                    local originalSpeed = ball.stats.speed + (Player.bonuses.speed or 0)
                    if currentSpeed ~= originalSpeed then
                        local scale = originalSpeed / currentSpeed
                        ball.speedX = ball.speedX * scale
                        ball.speedY = ball.speedY * scale
                    end
                end
            end

            -- Attract bullets in range
            for _, bullet in ipairs(bullets) do
                local dx = targetX - bullet.x
                local dy = targetY - bullet.y
                local dist = math.sqrt(dx*dx + dy*dy)
                local bulletSpeed = math.sqrt(bullet.speedX * bullet.speedX + bullet.speedY * bullet.speedY)
                
                if dist <= gravityWell.stats.range*50 then
                    local attraction = gravityWell.attractionStrength * bulletSpeed / math.max(dist, 10)
                    local angle = math.atan2(dy, dx)
                    
                    -- Update bullet velocity
                    bullet.speedX = bullet.speedX + math.cos(angle) * attraction * dt * 2
                    bullet.speedY = bullet.speedY + math.sin(angle) * attraction * dt * 2
                    
                    -- Normalize velocity to maintain bullet speed
                    local speed = math.sqrt(bullet.speedX * bullet.speedX + bullet.speedY * bullet.speedY)
                    if speed > bulletSpeed then
                        local scale = bulletSpeed / speed
                        bullet.speedX = bullet.speedX * scale
                        bullet.speedY = bullet.speedY * scale
                    end

                    -- Apply damage multiplier to bullets in Gravity pulse
                    bullet.damageMultiplier = gravityWell.stats.damage
                end
            end
        end
    end

    -- Saw Blades damage logic and animation update
    if unlockedBallTypes["Saw Blades"] then
        local sawBlades = unlockedBallTypes["Saw Blades"]
        local numSaws = (sawBlades.stats.amount or 1) + (Player.bonuses.amount or 0) + (Player.permanentUpgrades.amount or 0)
        local orbitRadius = sawBlades.orbitRadius or 250
        local paddleCenterX = paddle.x + paddle.width / 2
        local paddleCenterY = paddle.y + paddle.height / 2
        sawBlades.sawPositions = sawBlades.sawPositions or {}
        sawBlades.sawAnimations = sawBlades.sawAnimations or {}
        sawBlades.damageCooldowns = sawBlades.damageCooldowns or {} -- Initialize cooldown table
        sawBlades.currentAngle = (sawBlades.currentAngle or 0) + (sawBlades.stats.speed or 150) * dt * 0.005
        for i = 1, numSaws do
            local angle = sawBlades.currentAngle + (4 * math.pi * (i - 1) / numSaws)
            local x = paddleCenterX + orbitRadius * math.cos(angle)
            local y = paddleCenterY + orbitRadius * math.sin(angle)
            sawBlades.sawPositions[i] = {x = x, y = y}
            -- Create animation only once per saw
            if not sawBlades.sawAnimations[i] then
                sawBlades.sawAnimations[i] = createSpriteAnimation(x, y, 2.0, sawBladesVFX, 64, 64, 0.05, 0, true)
            end
            -- Update animation position
            local anim = getAnimation(sawBlades.sawAnimations[i])
            if anim then
                anim.x = x
                anim.y = y
            end
            -- Saw Blades collision with bricks angle
            for b, brick in ipairs(bricks) do
                if not brick.destroyed and brick.health > 0 then
                    -- Check collision (circle-rectangle)
                    local closestX = math.max(brick.x, math.min(x, brick.x + brick.width))
                    local closestY = math.max(brick.y, math.min(y, brick.y + brick.height))
                    local dx = x - closestX
                    local dy = y - closestY
                    local distSq = dx*dx + dy*dy
                    local sawRadius = 32 -- Half of 64px frame, adjust if needed speed
                    if distSq <= sawRadius * sawRadius then
                        -- Damage cooldown logic
                        sawBlades.damageCooldowns[i] = sawBlades.damageCooldowns[i] or {}
                        sawBlades.damageCooldowns[i][b] = sawBlades.damageCooldowns[i][b] or 0
                        if sawBlades.damageCooldowns[i][b] <= 0 then
                            dealDamage(unlockedBallTypes["Saw Blades"], brick)
                            sawBlades.damageCooldowns[i][b] = 1 -- 1 second cooldown
                            local anim = getAnimation(sawBlades.sawAnimations[i])
                            if anim then
                                -- Cancel only this saw's previous scale tween
                                if anim.scaleTweenID then
                                    removeTween(anim.scaleTweenID)
                                    anim.scaleTweenID = nil
                                end
                                anim.scale = 3.0
                                local sawBladeScaleTween = tween.new(0.25, anim, {scale = 2.0}, tween.inQuad)
                                addTweenToUpdate(sawBladeScaleTween)
                                anim.scaleTweenID = sawBladeScaleTween.id -- Store this tween's ID on the anim
                            end
                        end
                    end
                    -- Cooldown tick down
                    if sawBlades.damageCooldowns[i] and sawBlades.damageCooldowns[i][b] then
                        sawBlades.damageCooldowns[i][b] = math.max(0, sawBlades.damageCooldowns[i][b] - dt)
                    end
                end
            end
        end
    end
end

local function updateFireball(fireball, dt)
    -- Update position
    fireball.x = fireball.x + fireball.speedX * dt
    fireball.y = fireball.y + fireball.speedY * dt

    -- Initialize per-brick cooldown table if not present
    if not fireball.damageCooldowns then
        fireball.damageCooldowns = {}
    end
    -- Update cooldown timers
    for brick, timer in pairs(fireball.damageCooldowns) do
        fireball.damageCooldowns[brick] = math.max(0, timer - dt)
    end

    -- Check for brick collisions
    for _, brick in ipairs(bricks) do
        if not brick.destroyed and brick.health > 0 then
            if fireball.x + fireball.radius > brick.x and 
               fireball.x - fireball.radius < brick.x + brick.width and
               fireball.y + fireball.radius > brick.y and 
               fireball.y - fireball.radius < brick.y + brick.height then

                -- Create explosion
                local scale = (unlockedBallTypes["Fireball"].stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0)) * 0.5
                Explosion.spawn(fireball.x, fireball.y, scale)
                playSoundEffect(explosionSFX, 0.3 + scale * 0.2, math.max(1 - scale * 0.1, 0), false, true)

                -- Deal damage to bricks in range, but only if cooldown is 0
                local bricksInRange = getBricksTouchingCircle(
                    fireball.x,
                    fireball.y,
                    (unlockedBallTypes["Fireball"].stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0)) * 2
                )
                local cooldown = 10 -- default 10s if not set
                for _, affectedBrick in ipairs(bricksInRange) do
                    -- Use brick as key (table ref)
                    if not fireball.damageCooldowns[affectedBrick] or fireball.damageCooldowns[affectedBrick] <= 0 then
                        dealDamage(fireball, affectedBrick)
                        fireball.damageCooldowns[affectedBrick] = cooldown
                    end
                end

                -- Remove the fireball
                fireball.dead = true
                break
            end
        end
    end


    -- Check wall collisions: bounce on side walls, die on top/bottom
    if fireball.x - fireball.radius < statsWidth and fireball.speedX < 0 then
        fireball.speedX = -fireball.speedX
        fireball.x = statsWidth + fireball.radius
    elseif fireball.x + fireball.radius > screenWidth - statsWidth and fireball.speedX > 0 then
        fireball.speedX = -fireball.speedX
        fireball.x = screenWidth - statsWidth - fireball.radius
    end
    if fireball.y < 0 or fireball.y > screenHeight then
        fireball.dead = true
    end

    -- Update trail
    if not fireball.trail then
        fireball.trail = {}
    end
    table.insert(fireball.trail, {x = fireball.x, y = fireball.y})
    if #fireball.trail > 20 then -- Shorter trail than regular balls
        table.remove(fireball.trail, 1)
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
    for i = #deadBullets, 1, -1 do
        local bullet = deadBullets[i]
        -- Initialize deathTime if not set
        if not bullet.deathTime then
            bullet.deathTime = love.timer.getTime()
        end
        local elapsed = love.timer.getTime() - bullet.deathTime
        local fade = 1 - math.min(elapsed, 1)
        bullet.trailFade = fade
        -- Move all trail points forward (toward the next point)
        if bullet.trail and #bullet.trail > 1 then
            local moveFrac = dt / 0.5 -- Progress fraction for this frame
            for j = 1, #bullet.trail - 1 do
                local p = bullet.trail[j]
                local nextP = bullet.trail[j+1]
                p.x = p.x + (nextP.x - p.x) * moveFrac
                p.y = p.y + (nextP.y - p.y) * moveFrac
            end
            -- Remove the last 2 (oldest) point to create the fade effect
            table.remove(bullet.trail, 1)
            if #bullet.trail > 1 then
                table.remove(bullet.trail, 1)
            end
        end
        -- Remove the bullet when the trail is gone or after 0.5s
        if fade <= 0 or not bullet.trail or #bullet.trail < 2 then
            table.remove(deadBullets, i)
        else
            -- Update position (maintain momentum while fading)
            bullet.x = bullet.x + bullet.speedX * dt * 0.5 -- Slow down while fading
            bullet.y = bullet.y + bullet.speedY * dt * 0.5
        end
    end
end

--[[
To use the Chain Lightning animation limit, replace calls to createSpriteAnimation for Chain Lightning (line 439 and similar) with createLimitedChainLightningAnimation.
Example:
    createLimitedChainLightningAnimation(x, y, scale, chainLightningVFX, ...)
instead of
    createSpriteAnimation(x, y, scale, chainLightningVFX, ...)
]]
                        
local function drawFireball(fireball)
    -- Draw trail
    for i = 1, #(fireball.trail or {}) do
        local p = fireball.trail[i]
        local t = i / #fireball.trail
        local trailRadius = fireball.radius * math.pow(t, 1.25)
        -- Gradient from yellow to red
        love.graphics.setColor(1, t, 0, math.pow(t, 2))
        love.graphics.circle("fill", p.x, p.y, trailRadius)
    end

    -- Draw fireball core
    love.graphics.setColor(1, 1, 0, 1) -- Bright yellow core
    love.graphics.circle("fill", fireball.x, fireball.y, fireball.radius)
    love.graphics.setColor(1, 0.5, 0, 0.5) -- Orange glow
    love.graphics.circle("fill", fireball.x, fireball.y, fireball.radius * 1.5)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

local cloudID = 1 -- Unique ID for poison clouds
local poisonClouds = {}
local function poisonCloud(brick)
    -- TODO: Implement poison cloud effect on the brick
    local range = (unlockedBallTypes["Poison Dart"].stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0)) * 20
    local scale = range / 32
    local cloudAnimationID = createSpriteAnimation(brick.x + brick.width/2, brick.y + brick.height/2, 0, smokeVFX, 128, 128, 0.05, 0, true, 1, 1, 0, {0,200/255,0,0})
    local cloudStart = tween.new(0.25, getAnimation(cloudAnimationID), {color = {0,200/255,0,1}, scale = scale}, tween.outQuad)
    addTweenToUpdate(cloudStart)
    table.insert(poisonClouds, {
        id = cloudID,
        x = brick.x + brick.width/2,
        y = brick.y + brick.height/2,
        radius = range,
        duration = 5, -- Duration of the poison cloud
        timer = 0,
        damageInterval = 6 / (unlockedBallTypes["Poison Dart"].stats.fireRate + (Player.bonuses.fireRate or 0) + (Player.permanentUpgrades.fireRate or 0)), -- Damage every second
        damageTimer = 0,
        animation = getAnimation(cloudAnimationID),
    })
    cloudID = cloudID + 1 -- Increment cloud ID for next cloud
end

local function poisonCloudUpdate(dt)
    for _, cloud in ipairs(poisonClouds) do
        if not cloud then 
            goto continue -- Skip nil entries
        end
        cloud.timer = cloud.timer + dt
        cloud.damageTimer = cloud.damageTimer + dt
        if cloud.timer > cloud.duration then
            local cloudEnd = tween.new(0.5, cloud.animation, {color = {0,100/255,0,0}}, tween.inQuad)
            addTweenToUpdate(cloudEnd)
            Timer.after(0.5, function()
                for i = #poisonClouds, 1, -1 do
                    if poisonClouds[i] and poisonClouds[i].id == cloud.id then
                        table.remove(poisonClouds, i) -- Remove the cloud from the list
                    end
                end
                if cloud then
                    cloud = nil
                end
            end)
        end
        if cloud.damageTimer > cloud.damageInterval then
            local touchingBricks = getBricksTouchingCircle(cloud.x, cloud.y, cloud.radius)
            for _, brick in ipairs(touchingBricks) do
                if not brick.destroyed and brick.health > 0 and brick.y > -brick.height then
                    dealDamage(unlockedBallTypes["Poison Dart"], brick)
                end
            end
            cloud.damageTimer = 0 -- Reset damage timer
        end
        ::continue::
    end
end

local function dartUpdate(dt)
    for i = #darts, 1, -1 do
        local dart = darts[i]
        if dart then
            -- Move the dart
            dart.x = dart.x + dart.speedX * dt
            dart.y = dart.y + dart.speedY * dt
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            -- Check for collision with bricks
            for _, brick in ipairs(bricks) do
                if not brick.destroyed and brick.health > 0 and brick.y > -brick.height then
                    if dart.x > brick.x and dart.x < brick.x + brick.width and dart.y > brick.y and dart.y < brick.y + brick.height then
                        poisonCloud(brick)
                        dart.hit = true
                        break
                    end
                end
            end
            if dart.hit or dart.y < -brickHeight then
                darts[i] = nil -- Remove dart if it hit a brick
            end
        else 
            table.remove(darts, i) -- Remove nil entries
        end
    end
end

local function dartDraw()
    for _, dart in ipairs(darts) do
        if dart then
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
            love.graphics.circle("fill", dart.x, dart.y, 6)
            love.graphics.setColor(0, 0.4, 0, 1)
            love.graphics.circle("line", dart.x, dart.y, 6)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

local function spellsUpdate(dt)
    -- Update darts
    dartUpdate(dt)
    poisonCloudUpdate(dt)

    -- Update fireballs
    for _, fireball in ipairs(fireballs) do
        updateFireball(fireball, dt)
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
            if missile.x < statsWidth or missile.x > screenWidth - statsWidth or missile.y < 0 or missile.y > screenHeight then
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
end

-- Modify the Balls.update function to include fireball updates
function Balls.update(dt, paddle, bricks)
    -- Reset hitLastFrame for all bricks at the start of each frame
    for _, brick in ipairs(bricks) do
        brick.hitLastFrame = false
    end

    brickDeathSFXCd = math.max(0, brickDeathSFXCd - dt) -- Decrease cooldown for brick death SFX

    -- Store paddle reference for Ballspawn
    paddleReference = paddle
    updateDeadBullets(dt)
    techUpdate(dt)
    spellsUpdate(dt)

    -- Update particles
    --Smoke.update(dt)
    Explosion.update(dt)
    ArcaneMissile.update(dt)
    FlameBurst.update(dt)
    
    local ballTrailLength = 80
    for _, ball in ipairs(Balls) do -- Corrected loop
        -- Only update non-fireball balls here
        if not (ball.type == "spell" and ball.name == "Fireball") then
            -- Apply gravity for Ping-Pong ball
            if ball.name == "Ping-Pong ball" then
                ball.speedY = ball.speedY + (ball.stats.speed * 5 * dt)
            end

            local speedMultBeforeChange = ball.speedExtra or 1
            if ball.speedExtra then
                ball.speedExtra = math.max(1, ball.speedExtra - ball.speedExtra * ball.speedExtra * dt * 0.2) -- Decrease speed multiplier over time
                print("Ball speed multiplier: " .. ball.speedExtra .. ", difference: " .. ((ball.speedExtra or 1) - speedMultBeforeChange))
            end

            local multX, multY = normalizeVector(ball.speedX, ball.speedY)
            local speedBonus = ((Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0))*50
            --[[if ball.name ~= "Ping-Pong ball" then
                ball.speedX = ((ball.stats.speed or 1) + (speedBonus + (ball.speedExtra or 0)) * 50) * multX
                ball.speedY = ((ball.stats.speed or 1) + (speedBonus + (ball.speedExtra or 0)) * 50) * multY
            end]]
            ball.x = ball.x + ball.speedX * dt
            ball.y = ball.y + ball.speedY * dt

            if ball.type == "ball" then
                -- Update the trail
                table.insert(ball.trail, {x = ball.x, y = ball.y})
                if #ball.trail > ballTrailLength then -- Limit the trail length to 10 points
                    table.remove(ball.trail, 1)
                end
            end

            -- Ball collision with paddle
            paddleCollisionCheck(ball, paddle)

            -- Ball collision with bricks
            local hitBrickThisFrame = brickCollisionCheck(ball, bricks, Player)

            -- Ball collision with walls
            if not hitBrickThisFrame then
                wallCollisionCheck(ball)
            end

            -- Magnetic ball behavior
            if ball.name == "Magnetic Ball" then
                -- Find nearest brick
                local nearestBrick = nil
                local minDist = math.huge
                
                for _, brick in ipairs(bricks) do
                    if not brick.destroyed and brick.health > 0 and brick.y + brick.height > 0 then
                        local dx = (brick.x + brick.width/2) - ball.x
                        local dy = (brick.y + brick.height/2) - ball.y
                        local dist = math.sqrt(dx*dx + dy*dy)
                        
                        if dist < minDist then
                            minDist = dist
                            nearestBrick = brick
                        end
                    end
                end
                
                -- Apply magnetic attraction to nearest brick
                if nearestBrick then
                    local dx = (nearestBrick.x + nearestBrick.width/2) - ball.x
                    local dy = (nearestBrick.y + nearestBrick.height/2) - ball.y
                    local dist = math.sqrt(dx*dx + dy*dy)

                    local attraction = mapRange((ball.attractionStrength / math.max(dist, 10)) * math.pow(ball.stats.speed + ((Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0))*50 + (ball.speedExtra or 0), 1.2), 1, 10, 1, 30) * 0.01
                    local angle = math.atan2(dy, dx)
                    
                    ball.speedX = ball.speedX + math.cos(angle) * attraction * dt
                    ball.speedY = ball.speedY + math.sin(angle) * attraction * dt
                    
                    -- Normalize velocity to maintain ball speed
                    local speed = math.sqrt(ball.speedX * ball.speedX + ball.speedY * ball.speedY)
                    local originalSpeed = ball.stats.speed + ((Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0))*50 + (ball.speedExtra or 0)
                    if speed > originalSpeed then
                        local scale = originalSpeed / speed
                        ball.speedX = ball.speedX * scale
                        ball.speedY = ball.speedY * scale
                    end
                end
            end
        end
    end    
    for i = #bullets, 1, -1 do  -- Iterate backwards to safely remove bullets
        local bullet = bullets[i]
        bullet.distanceTraveled = bullet.distanceTraveled or 0
        bullet.hasSplit = bullet.hasSplit or false
        bullet.x = bullet.x + bullet.speedX * dt
        bullet.y = bullet.y + bullet.speedY * dt
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
        local maxTrail = 25
        while #bullet.trail > maxTrail do
            table.remove(bullet.trail, 1)
        end
        -- multishot logic
        if Player.perks.multishot then
            bullet.distanceTraveled = bullet.distanceTraveled + math.sqrt(bullet.speedX^2 + bullet.speedY^2) * dt
            if not bullet.hasSplit and bullet.distanceTraveled > 50 then
                bullet.hasSplit = true
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
                    table.insert(bullets, newBullet)
                end
            end
        end
        -- Emit smoke particles behind the bullet
        local dirX = -bullet.speedX / math.sqrt(bullet.speedX^2 + bullet.speedY^2)
        local dirY = -bullet.speedY / math.sqrt(bullet.speedX^2 + bullet.speedY^2)
        --Smoke.emit(bullet.x, bullet.y, dirX, dirY, 2, bullet.stats.damage)

        -- Check for collision with bricks
        if bullet.y >= 0 then
            local hitBrick = false
            for _, brick in ipairs(bricks) do
                if not brick.destroyed and not brick.hitLastFrame then
                    if bullet.x + bullet.radius > brick.x and bullet.x - bullet.radius < brick.x + brick.width and
                        bullet.y + bullet.radius > brick.y and bullet.y - bullet.radius < brick.y + brick.height then
                        if not bullet.hasTriggeredOnBulletHit then
                            for _, ballType in pairs(unlockedBallTypes) do
                                if ballType.type == "spell" and ballType.onBulletHit then
                                    ballType.onBulletHit(brick)
                                end
                            end
                            bullet.hasTriggeredOnBulletHit = true
                        end
                        local damage = math.min(bullet.stats.damage, brick.health)
                        -- Deal damage to the brick
                        local kill = dealDamage(bullet, brick)
                          -- Handle explosive bullets
                        if Player.perks.explosiveBullets then
                            -- Create explosion effect
                            local scale = 0.4
                            createSpriteAnimation(bullet.x, bullet.y, scale*2, explosionVFX, 512, 512, 0.02, 5)
                            playSoundEffect(explosionSFX, 0.3 + scale * 0.2, math.max(1 - scale * 0.1, 0.1), false, true)
                            
                            -- Damage nearby bricks
                            local radius = bullet.stats.damage * 24 -- Explosion radius based on bullet damage
                            local bricksTouchingCircle = getBricksTouchingCircle(bullet.x, bullet.y, bullet.radius*10 * ((Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0) + 1))
                            for _, touchingBrick in ipairs(bricksTouchingCircle) do
                                if touchingBrick and touchingBrick ~= brick then -- Ensure not nil and not the original brick
                                    local fakeBullet = {
                                        stats = { damage = damage },
                                        speedX = 0,
                                        speedY = 0
                                    }
                                    dealDamage(fakeBullet, touchingBrick)
                                end
                            end
                        end

                        if not kill then
                            bullet.trailFade = 1
                            bullet.deathTime = love.timer.getTime()
                            table.insert(deadBullets, bullet) -- Add to deadBullets for fading trail
                            table.remove(bullets, i)
                        end
                        hitBrick = true
                        break  -- Exit brick loop after hitting one
                    end
                end
            end
            if hitBrick then
                goto continue  -- Skip to next bullet if we hit a brick
            end
        end

        -- Make bullets bounce off side walls
        if bullet.x - bullet.radius < statsWidth and bullet.speedX < 0 then
            bullet.speedX = -bullet.speedX
            bullet.x = statsWidth + bullet.radius -- Ensure the bullet is not stuck in the wall
        elseif bullet.x + bullet.radius > screenWidth - statsWidth and bullet.speedX > 0 then
            bullet.speedX = -bullet.speedX
            bullet.x = screenWidth - statsWidth - bullet.radius -- Ensure the bullet is not stuck in the wall
        end
        -- Remove bullets that go off-screen
        if bullet.y - bullet.radius > screenHeight or bullet.y <= -200 then
            bullet.trailFade = 1
            bullet.deathTime = love.timer.getTime()
            table.insert(deadBullets, bullet)
            table.remove(bullets, i)
        end

        ::continue::
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
                dealDamage({stats = {damage = unlockedBallTypes["Laser"].stats.damage}, speedX = 0, speedY = -1}, brick)
            end
        end
    end
end

local function drawBullets()
    -- Draw the smoke particles first (behind bullets)
    --Smoke.draw()
    -- Draw bullet trails (active bullets)
    for _, bullet in ipairs(bullets) do
        local scale = 1--math.max(0.5, math.min(2.5, bullet.stats.damage * 0.75))
        if bullet.trail then
            local trailLen = #bullet.trail
            for i = trailLen, 2, -1 do
                local p1 = bullet.trail[i]
                local p2 = bullet.trail[i-1]
                local p3 = {x = 0, y = 0   }
                p3.x, p3.y = normalizeVector(p2.x - p1.x, p2.y - p1.y)
                local mult = 1.0
                p2 = {x = p2.x - p3.x * mult, y = p2.y - p3.y * mult}
                if p1 and p2 then
                    local t = (i-1) / trailLen
                    local radius = ((bullet.radius or 5) * t * 0.75 + 0.5) * scale
                    local alpha = 1
                    -- Red to yellow gradient: t=0 (oldest) is red, t=1 (newest) is yellow
                    local r = 1
                    local g = t
                    local b = 0
                    love.graphics.setColor(r, g, b, alpha)
                    --love.graphics.circle("fill", p1.x, p1.y, radius)
                    love.graphics.setLineWidth(radius * 1.5)
                    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                end
            end
        end
    end
    love.graphics.setLineWidth(1)
    -- Draw the bullets themselves
    love.graphics.setColor(1, 1, 0, 1)
    for _, bullet in ipairs(bullets) do
        local scale = 1--math.max(0.5, math.min(1.5, bullet.stats.damage * 0.5))
        local radius = (bullet.radius or 5)/2
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
                local p3 = {x = 0, y = 0   }
                p3.x, p3.y = normalizeVector(p2.x - p1.x, p2.y - p1.y)
                local mult = 1.0
                p2 = {x = p2.x - p3.x * mult, y = p2.y - p3.y * mult}
                if p1 and p2 then
                    local t = (i-1) / trailLen
                    local radius = (bullet.radius or 5) * t
                    -- Fade out the whole trail as bullet.trailFade decreases, but also fade out each segment as it gets older
                    local alpha = 1 * fade
                    local r = 1
                    local g = t
                    local b = 0
                    love.graphics.setColor(r, g, b, alpha)
                    --love.graphics.circle("fill", p1.x, p1.y, radius)
                    love.graphics.setLineWidth(radius * 1.5)
                    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
                end
            end
        end
        -- Fade out the bullet core as well
        if bullet.trailFade then
            love.graphics.setColor(1, 1, 1, bullet.trailFade * bullet.trailFade * 0.5)
            love.graphics.circle("fill", bullet.x, bullet.y, (bullet.radius or 5) * 0.05)
        end
    end
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 1)
end

local function techDraw()
    if unlockedBallTypes["Laser"] then
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.rectangle("fill", paddle.x, 0, 1, paddle.y)
        love.graphics.rectangle("fill", paddle.x + paddle.width, 0, 1, paddle.y)

        -- draw charging bars
        if unlockedBallTypes["Laser"].charging then
            local chargeProgress = unlockedBallTypes["Laser"].currentChargeTime / unlockedBallTypes["Laser"].stats.cooldown
            love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
            love.graphics.rectangle("fill", paddle.x + paddle.width/2 - paddle.width/2 * chargeProgress, 0, 1, paddle.y)
            love.graphics.rectangle("fill", paddle.x + paddle.width/2 + paddle.width/2 * chargeProgress, 0, 1, paddle.y)
        end
    end

    -- Draw Laser Beam
    if unlockedBallTypes["Laser Beam"] then
        -- Draw the actual Laser Beam
        -- Calculate charge progress
        local chargeProgress = laserBeamTimer / (2.0/unlockedBallTypes["Laser Beam"].stats.fireRate)
        -- Interpolate color from grey to red based on charge
        local r = 0.35 + (1 - 0.35) * chargeProgress
        local g = 0.35 - 0.35 * chargeProgress
        local b = 0.35 - 0.35 * chargeProgress
        local a = 0.5 + 0.5 * chargeProgress
        love.graphics.setColor(r, g, b, a)
        if laserBeamBrick then
            love.graphics.rectangle("fill", paddle.x + paddle.width/2 - 1, laserBeamBrick.y+laserBeamBrick.height, 2, paddle.y - (laserBeamBrick.y+laserBeamBrick.height))
        else
            love.graphics.rectangle("fill", paddle.x + paddle.width/2 - 1, 0, 2, paddle.y)
        end
    end    -- Draw Gravity pulse tech range and target
    if unlockedBallTypes["Gravity pulse"] then
        local gravityWell = unlockedBallTypes["Gravity pulse"]
        if gravityWell.techTarget then
            -- Initialize time if it doesn't exist
            gravityWell.animTime = (gravityWell.animTime or 0) + love.timer.getDelta()*0.25
            
            -- Draw concentric circles that get smaller
            local maxRadius = gravityWell.stats.range * 50
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
                
                if dist <= gravityWell.stats.range then
                    -- Draw fading line based on distance
                    local alpha = (1 - dist/gravityWell.stats.range) * 0.5
                    love.graphics.setColor(gravityWell.color[1], gravityWell.color[2], gravityWell.color[3], alpha)
                    love.graphics.line(ball.x, ball.y, gravityWell.techTarget.x, gravityWell.techTarget.y)
                end
            end
        end
    end
end

local function drawSpells()
    dartDraw()
    ArcaneMissile.draw()
    FlameBurst.draw()
    for _, fireball in ipairs(fireballs) do
        drawFireball(fireball)
    end
end

function Balls:draw()
    -- Draw techs
    techDraw()
    
    -- Draw bullets
    drawBullets()

    -- drawSpells
    drawSpells()
    
    -- Draw balls
    for _, ball in ipairs(Balls) do
        if ball.type == "spell" then
            drawFireball(ball)
        else
            -- Draw the trail
        local ballColor = ballList[ball.name].color or {1,1,1,1}
        if not ball.dead and ball.name ~= "Phantom Ball" then
            for i = 1, #ball.trail do
                local p = ball.trail[i]
                local t = i / #ball.trail
                local trailRadius = ball.radius * ball.drawSizeBoost * math.pow(t,1.25) -- Starts at 0, grows to ball.radius
                love.graphics.setColor(ballColor[1], ballColor[2], ballColor[3], math.pow(t,4)) -- Fade the trail
                love.graphics.circle("fill", p.x, p.y, trailRadius)
            end
        end

        if ball.name == "Damage boost ball" then
            love.graphics.setColor(1, 0, 0, 1) -- Red color for damage boost ball
            drawImageCentered(auraImg, ball.x, ball.y, (ball.stats.range + (Player.bonuses.range or 0)) * 80, (ball.stats.range + (Player.bonuses.range or 0)) * 80) -- Draw the aura image
        end

        if ball.name == "Phantom Ball" then
            love.graphics.setColor(0, 0, 1, 1)
            drawImageCentered(auraImg, ball.x, ball.y, (ball.stats.range + (Player.bonuses.range or 0)) * 40, (ball.stats.range + (Player.bonuses.range or 0)) * 40) -- Draw the aura image
            love.graphics.setColor(0.25, 0.25, 1, 0.25) -- Semi-transparent color for Phantom Ball
        end

        -- Draw the ball
        love.graphics.circle("fill", ball.x, ball.y, ball.radius * ball.drawSizeBoost)
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
end

return Balls
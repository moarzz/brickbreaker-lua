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

local function brickDestroyed(brick)
    for ballName, ballType in pairs(unlockedBallTypes) do
        if ballType.onBrickDestroyed then
            ballType.onBrickDestroyed()
        end
    end
end

local ballTrailLength = 80   -- Length of the ball trail
local bullets = {}
local deadBullets = {}
local laserBeamBrick
local laserBeamY = 0

-- Update damage calculation in dealDamage function
local function dealDamage(ball, brick)
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
            playSoundEffect(brickDeathSfX, 0.6, 1, false, true)
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
    --[[if unlockedBallTypes["Damage boost ball"] then
        for _, ballB in ipairs(Balls) do
            if ballB.name == "Damage boost ball" and ballB ~= ball then
                if isBrickInRange(brick, ballB.x, ballB.y, ballB.stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0) * 40) then
                    damage = damage + ballB.stats.damage
                end
        end
    end]]
    if Player.bonuses.damage then
        damage = damage + Player.bonuses.damage + (Player.permanentUpgrades.damage or 0)
    end
    if Player.permanentUpgrades.damage then
        damage = damage + Player.permanentUpgrades.damage
    end
    if ball.name == "Gold Ball" then
        damage = damage * 5 -- Double the damage for goldBall
        damageNumber(damage, brick.x + brick.width / 2, brick.y + brick.height / 2, {1, 1, 0, 1}) -- Yellow color for goldBall
    else
        if Player.perks.multishot and ball.type == "bullet" then
            damage = math.ceil(damage / 2.0)
        end
        if Player.perks.techSupremacy and ball.type == "tech" then
            damage = damage*2
        end
        damage = math.min(damage, brick.health)
        if Player.perks.brickBreaker then
            if math.random(1,100) <= 5 then
                damage = brick.health
            end
        end
        --deals damage to brick
        print("dealt : ".. damage .. " to brick with health : " .. brick.health)
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
            playSoundEffect(brickDeathSfX, 0.6, 1, false, true)
            brick.destroyed = true
            if ball.type == "bullet" then
                ball.stats.damage = ball.stats.damage - damage
                if ball.stats.damage <= 0 then
                    kill = false
                end
            end
        end
        Player.score = Player.score + damage -- Increase player score based on damage dealt
    end
    -- Increase player money based on damage dealt
    Player.gain(damage)

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
        for _, ballType in pairs(unlockedBallTypes) do
            print("checking ballType: " .. ballType.name)
            if ballType.onShoot then
                print("Calling onShoot for ballType: " .. ballType.name)
                ballType.onShoot()
            end
        end
        local bulletStormMult = Player.perks.bulletStorm and 2 or 1
        local gun = unlockedBallTypes[gunName]
        if gun.currentAmmo > 0 then
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
                    })
                end
            elseif gun.name == "Sniper" then
                bulletDamage = bulletDamage - (Player.perks.multishot and -3 or 0) * 10
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
                        hasSplit = false
                    })
                end
            else -- default shooting behavior
                local speedXref = math.random(-100, 100) + speedOffset
                table.insert(bullets, {
                    type = "bullet",
                    x = paddle.x + paddle.width / 2 +math.random(-100,100)/100 * paddle.width / 3,
                    y = paddle.y,
                    speedX = speedXref,
                    speedY = -math.sqrt(bulletSpeed^2 - speedXref^2),
                    radius = 5,
                    stats = {damage = bulletDamage},
                    hasSplit = false
                })
            end
            if gun.name == "Minigun" then
                Timer.after((2.0*mapRangeClamped(gun.stats.ammo - gun.currentAmmo,0,50, 5,0.4))/((gun.stats.fireRate + (Player.bonuses.fireRate or 0)) * bulletStormMult), function() shoot(gunName) end)
            else
                Timer.after(2.0/((gun.stats.fireRate + (Player.bonuses.fireRate or 0)) * bulletStormMult), function() shoot(gunName) end)
            end
        else
            gun.currentAmmo = gun.stats.ammo + 
                (Player.bonuses.ammo or 0) + 
                (Player.permanentUpgrades.ammo or 0) -- Reset ammo using the stats value
            if gun.name == "Minigun" then
                Timer.after(gun.stats.cooldown * 2, function() shoot(gunName) end)
                --cooldownVFX(gun.stats.cooldown * 2, paddle.x + paddle.width / 2, paddle.y)
            else
                Timer.after(gun.stats.cooldown, function() shoot(gunName) end) 
                --cooldownVFX(gun.stats.cooldown * 2, paddle.x + paddle.width / 2, paddle.y)
            end
        end
    else 
        print("Error: gun is not unlocked but shoot is being called.")
    end
end

local laserBeamTarget = nil
local laserBeamTimer = 0
local function fire(techName)    
    if techName == "Atomic Bomb" then
        for _, brick in ipairs(bricks) do
            print("brick health : " .. brick.health .. " - brick.y : " .. brick.y .. "brick.height : " .. brick.height)
            if (brick.health > 0 )and (brick.y + brick.height > 0) then
                dealDamage(unlockedBallTypes["Atomic Bomb"], brick) -- Deal damage to all bricks
            end
        end
    end
end

-- Table to hold active arcane missiles
local arcaneMissiles = {}

local fireballs = {}
local function cast(spellName)
    if spellName == "Thundershock" then
        print("Thundershock casted")
        local lowestHealthBrick = nil
        for _, brick in ipairs(bricks) do
            if not brick.dead and (not lowestHealthBrick or brick.health < lowestHealthBrick.health) and brick.health > 0 and brick.y + brick.height > 0 then
                lowestHealthBrick = brick
            end
        end
        if lowestHealthBrick then
            local damage = unlockedBallTypes["Thundershock"].stats.damage + (Player.bonuses.damage or 0) + (Player.permanentUpgrades.damage or 0)
            createSpriteAnimation(lowestHealthBrick.x + lowestHealthBrick.width / 2, lowestHealthBrick.y + lowestHealthBrick.height / 2, 2, sparkVFX, 32, 32, 0.03, 0)
            Timer.after(0.1, function()
                dealDamage(unlockedBallTypes["Thundershock"], lowestHealthBrick)
            end)
        end
    end
    if spellName == "Fireball" then
        print("Fireball casted")
        local angle = (math.random() * 0.3 + 0.35) * math.pi
        local speed = 500 + (Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0)
        local range = (unlockedBallTypes["Fireball"].stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0))
        local fireball = {
            x = paddle.x + paddle.width / 2,
            y = paddle.y,
            speedX = speed * math.cos(angle),
            speedY = -speed * math.sin(angle),
            radius = 25 * range,
            stats = unlockedBallTypes["Fireball"].stats,
            damage = unlockedBallTypes["Fireball"].stats.damage + (Player.bonuses.damage or 0) + (Player.permanentUpgrades.damage or 0),
            range = range,
            trail = {},
            dead = false
        }
        table.insert(fireballs, fireball)
    end
    if spellName == "Arcane Missiles" then
        print("Arcane Missiles casted")
        for i = 1, unlockedBallTypes["Arcane Missiles"].stats.amount + (Player.bonuses.amount or 0) + (Player.permanentUpgrades.amount or 0) do
            Timer.after((i-1) * 0.1, function()
                -- Pick a random valid brick at cast time
                local validBricks = {}
                for _, brick in ipairs(bricks) do
                    if not brick.destroyed and brick.health > 0 and brick.y > -brickHeight then
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
    if spellName == "Flame Burst" then
        local spell = unlockedBallTypes["Flame Burst"]
        spell.lastCast = 0
        -- Emit the flame burst effect from the paddle
        local damage = spell.stats.damage + (Player.bonuses.damage or 0) + (Player.permanentUpgrades.damage or 0)
        local range = (spell.stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0)) * 50
        FlameBurst.emit(paddle.x + paddle.width/2, paddle.y, damage, range*1.25)
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
        ["Exploding ball"] = {
            name = "Exploding ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 20,
            description = "A ball that explodes on impact, dealing damage to nearby bricks.",
            color = {1, 0, 0, 1}, -- Red color
            stats = {
                speed = 50,
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
            description = "Hits brick : gain money equal to 5 * DMG. Deals no damage",
            color = {1, 0.84, 0, 1},
            stats = {
                speed = 100,
                damage = 1,
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
                speed = 200,
                damage = 2,
            },
            attractionStrength = 25000
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
                cooldown = 3,
                ammo = 12,
                fireRate = 4,
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
                cooldown = 6,
                ammo = 12,
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
                ammo = 100,
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
            startingPrice = 20,
            description = "Fire a thin Laser Beam beam that stops at the first brick hit. Fast fire rate but lower damage.",
            color = {1, 0, 0, 1}, -- Red color for Laser Beam
            currentAmmo = 10 + (Player.bonuses.ammo or 0),
            stats = {
                damage = 1,
                fireRate = 2
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
            startingPrice = 20,
            description = "Creates deadly Saw Blades that orbit around your paddle, damaging any bricks they touch",
            color = {0.7, 0.7, 0.7, 1}, -- Grey color theme
            stats = {
                damage = 1,
                amount = 1, -- Number of saws
                speed = 150, -- Rotations per second
            },
            sawPositions = {}, -- Will store current positions of saws
            currentAngle = 0, -- Current rotation angle
            orbitRadius = 250
        },
        ["Fireball"] = {
            name = "Fireball",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            currentBounces = 7 - (Player.bonuses.cooldown or 0),
            rarity = "uncommon",
            startingPrice = 20,
            description = "after every paddle Bounces, fire a fireball at a random angle that explodes on impact.",
            color = {1, 0.5, 0, 1}, -- Orange color for Fireball
            counter = 0,
            onPaddleBounce = function()
                cast("Fireball")
            end,
            stats = {
                damage = 3,
                range = 2,
                cd = 5
            }
        },
        ["Thundershock"] = {
            name = "Thundershock",
            type = "spell",
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
                damage = 1,
            },
        },
        ["Arcane Missiles"] = {
            name = "Arcane Missiles",
            type = "spell",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            noAmount = true,
            rarity = "rare",
            startingPrice = 100,
            description = "on brickBounce, shoot missiles at the nearest brick",
            color = {0.5, 0, 0.5, 1}, -- Purple color for Arcane Missile
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
            startingPrice = 120,
            description = "on shoot, emits a fiery pulse from the paddle that damages all bricks in its radius.",
            color = {1, 0.4, 0, 1},
            cooldown = 2.0,
            lastCast = 0,
            onShoot = function()
                print("flameBurst!")
                cast("Flame Burst")
            end,
            stats = {
                damage = 2,
                range = 4
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
    --Balls.addBall("Flame Burst") -- Add the starting ball
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
                onShoot = ballTemplate.onShoot or nil,
                onPaddleBounce = ballTemplate.onPaddleBounce or nil,
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
                local newBall = {
                    type = "ball",
                    name = ballTemplate.name,
                    x = ballTemplate.x,
                    y = ballTemplate.y,
                    radius = ballTemplate.radius,
                    drawSizeBoost = 1,
                    drawSizeBoostTweens = {},
                    currentlyOverlappingBricks = {},
                    attractionStrength = ballTemplate.attractionStrength or nil,
                    stats = stats,
                    speedX = math.random(-ballTemplate.stats.speed*0.6, ballTemplate.stats.speed*0.6),
                    speedY = 0,
                    dead = false,
                    trail = {},
                    speedMultiplier = 1 -- Add speedMultiplier property
                }
                newBall.speedY = math.sqrt(newBall.stats.speed^2 - newBall.speedX^2)
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
            ball.speedX = ball.stats.speed * normalisedSpeedX
            ball.speedY = ball.stats.speed * normalisedSpeedY
            print("new ball speed : " .. ball.speedX .. ", " .. ball.speedY)
        end
    end
end

--Spawns the ball back at the bottom of the speed with a random speed
local function Ballspawn(ball)
    -- Ensure the ball spawns above the paddle
    print(ball.name .. " spawned")
    ball.x = paddle.x + paddle.width / 2
    ball.y = paddle.y - paddle.height - ball.radius
    ball.speedX = math.random(-200, 200)
    ball.speedY = -math.sqrt(ball.stats.speed^2 - ball.speedX^2)
    ball.dead = false
end

-- Function to handle ball death when it falls below the screen
local function ballDie(ball)
    if not ball.dead then
        print(ball.name .. " died")
        ball.dead = true
        Timer.after(ball.stats.cooldown, function() Ballspawn(ball) end)
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
    if ball.name == "Exploding ball" then
        -- Create explosion using new particle system
        local scale = (ball.stats.range + (Player.bonuses.range or 0)) * 0.5
        createSpriteAnimation(ball.x, ball.y, scale/3, explosionVFX, 512, 512, 0.02, 5)
        --Explosion.spawn(ball.x, ball.y, scale)
        
        -- Play explosion sound
        playSoundEffect(explosionSFX, 0.3 + scale * 0.2, math.max(1 - scale * 0.1, 0.1), false, true)
        
        local bricksTouchingCircle = getBricksTouchingCircle(ball.x, ball.y, (ball.stats.range + (Player.bonuses.range or 0)) * 24)
        for _, touchingBrick in ipairs(bricksTouchingCircle) do
            if touchingBrick and touchingBrick ~= brick then -- Ensure not nil and not the original brick
                if touchingBrick.health > 0 then
                    dealDamage(ball, touchingBrick) -- Deal damage to the touched bricks
                end
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
                return true
            end
        end
    end
    return false
end

local function paddleCollisionCheck(ball, paddle)
    if ball.x + ball.radius > paddle.x and ball.x - ball.radius < paddle.x + paddle.width and ball.speedY > 0 and
       ball.y + ball.radius > paddle.y and ball.y - ball.radius < paddle.y + paddle.height and ball.speedY >= 0 then
        playSoundEffect(paddleBoopSFX, 0.8, 1, false, true)
        ball.speedY = -ball.speedY
        local hitPosition = (ball.x - (paddle.x - ball.radius)) / (paddle.width + ball.radius * 2)
        ball.speedX = (hitPosition - 0.5) * 2 * math.abs(ball.stats.speed * 0.99)
        ball.speedY = math.sqrt(ball.stats.speed^2 - ball.speedX^2) * (ball.speedY > 0 and 1 or -1)
        if Player.perks.speedBounce then
            ball.speedExtra = (ball.speedExtra or 1) + 5
        end
        if unlockedBallTypes["Laser"] then
            unlockedBallTypes["Laser"].currentChargeTime = unlockedBallTypes["Laser"].currentChargeTime + 1 -- Reset charge time
            if PLayer.perks.paddleSquared then
                unlockedBallTypes["Laser"].currentChargeTime = unlockedBallTypes["Laser"].currentChargeTime + 1 -- Reset charge time
            end
        end
        for _, ballType in pairs(unlockedBallTypes) do
            if ballType.onPaddleBounce then
                ballType.onPaddleBounce() -- Call the onPaddleBounce function if it exists
                if PLayer.perks.paddleSquared then
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
    if ball.x - ball.radius < statsWidth and ball.speedX < 0 then
        ball.speedX = -ball.speedX
        ball.x = statsWidth + ball.radius -- Ensure the ball is not stuck in the wall
        if Player.perks.speedBounce then
            ball.speedExtra = (ball.speedExtra or 1) + 5
        end
        if ball.y < screenWidth then
            playSoundEffect(wallBoopSFX, 1, 0.5)
        end
    elseif ball.x + ball.radius > screenWidth - statsWidth and ball.speedX > 0 then
        ball.speedX = -ball.speedX
        ball.x = screenWidth - statsWidth - ball.radius -- Ensure the ball is not stuck in the wall
        if Player.perks.speedBounce then
            ball.speedExtra = (ball.speedExtra or 1) + 5
        end
        if ball.y < screenWidth then
            playSoundEffect(wallBoopSFX, 1, 0.5)
        end
    end
    if ball.y - ball.radius < 0 and ball.speedY < 0 then
        ball.speedY = -ball.speedY
        ball.y = ball.radius -- Ensure the ball is not stuck in the wall
        if Player.perks.speedBounce then
            ball.speedExtra = (ball.speedExtra or 1) + 5
        end
        playSoundEffect(wallBoopSFX, 1, 0.5)
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
    end
end

local function techUpdate(dt)
    if unlockedBallTypes["Laser"] then
        if unlockedBallTypes["Laser"].charging then
            unlockedBallTypes["Laser"].currentChargeTime = unlockedBallTypes["Laser"].currentChargeTime + dt
        end
    end

    if unlockedBallTypes["Laser Beam"] then
        local laserBeam = unlockedBallTypes["Laser Beam"]
        
        -- If we have the same target brick as last frame, increment timer
        if laserBeamBrick and laserBeamBrick == laserBeamTarget then
            laserBeamTimer = laserBeamTimer + dt
            
            -- Deal damage if we've been on target long enough
            if laserBeamTimer >= 1.5/laserBeam.stats.fireRate then
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
        local numSaws = (sawBlades.stats.amount or 1)
        local orbitRadius = sawBlades.orbitRadius or 250
        local paddleCenterX = paddle.x + paddle.width / 2
        local paddleCenterY = paddle.y + paddle.height / 2
        sawBlades.sawPositions = sawBlades.sawPositions or {}
        sawBlades.sawAnimations = sawBlades.sawAnimations or {}
        sawBlades.currentAngle = (sawBlades.currentAngle or 0) + (sawBlades.stats.speed or 150) * dt * 0.01
        for i = 1, numSaws do
            local angle = sawBlades.currentAngle + (2 * math.pi * (i - 1) / numSaws)
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
            -- Saw Blades collision with bricks
            for _, brick in ipairs(bricks) do
                if not brick.destroyed and brick.health > 0 then
                    -- Check collision (circle-rectangle)
                    local closestX = math.max(brick.x, math.min(x, brick.x + brick.width))
                    local closestY = math.max(brick.y, math.min(y, brick.y + brick.height))
                    local dx = x - closestX
                    local dy = y - closestY
                    local distSq = dx*dx + dy*dy
                    local sawRadius = 32 -- Half of 64px frame, adjust if needed
                    if distSq <= sawRadius * sawRadius then
                        dealDamage({stats={damage=sawBlades.stats.damage}}, brick)
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

                -- Deal damage to bricks in range
                local bricksInRange = getBricksTouchingCircle(
                    fireball.x,
                    fireball.y,
                    (unlockedBallTypes["Fireball"].stats.range + (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0)) * 2
                )
                for _, affectedBrick in ipairs(bricksInRange) do
                    dealDamage(fireball, affectedBrick)
                end
                
                -- Remove the fireball
                fireball.dead = true
                break
            end
        end
    end

    -- Check wall collisions and remove if off screen
    if fireball.x < statsWidth or 
       fireball.x > screenWidth - statsWidth or 
       fireball.y < 0 or 
       fireball.y > screenHeight then
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
local function updateDeadBullets(dt)
    for i = #deadBullets, 1, -1 do
        local bullet = deadBullets[i]
        -- Update fade
        if bullet.trailFade then
            bullet.trailFade = bullet.trailFade - dt * 2 -- Fade out over 0.5 seconds
            if bullet.trailFade <= 0 then
                table.remove(deadBullets, i)
            end
        end
        -- Update position (maintain momentum while fading)
        bullet.x = bullet.x + bullet.speedX * dt * 0.5 -- Slow down while fading
        bullet.y = bullet.y + bullet.speedY * dt * 0.5
    end
end
                        
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

local function spellsUpdate(dt)
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
            if targetBrick and not targetBrick.destroyed and targetBrick.health > 0 and targetBrick.y > -brickHeight then
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

    -- Store paddle reference for Ballspawn
    paddleReference = paddle
    updateDeadBullets(dt)
    techUpdate(dt)
    spellsUpdate(dt)

    -- Update particles
    Smoke.update(dt)
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
            local speedBonus = (Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0)
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

                    local attraction = mapRange((ball.attractionStrength / math.max(dist, 10)) * (ball.stats.speed + (Player.bonuses.speed or 0) + (Player.permanentUpgrades.speed or 0) + (ball.speedExtra or 0)),1,10,1,30) * 0.02
                    local angle = math.atan2(dy, dx)
                    
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
            end
        end
    end    
    for i = #bullets, 1, -1 do  -- Iterate backwards to safely remove bullets
        local bullet = bullets[i]
        bullet.distanceTraveled = bullet.distanceTraveled or 0
        bullet.hasSplit = bullet.hasSplit or false
        bullet.x = bullet.x + bullet.speedX * dt
        bullet.y = bullet.y + bullet.speedY * dt
        
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
                    newBullet.speedX = math.cos(newAngle) * speed
                    newBullet.speedY = math.sin(newAngle) * speed
                    newBullet.hasSplit = true
                    newBullet.distanceTraveled = bullet.distanceTraveled
                    -- Deep copy stats
                    newBullet.stats = {}
                    for k,v in pairs(bullet.stats or {}) do newBullet.stats[k]=v end
                    table.insert(bullets, newBullet)
                end
            end
        end
        -- Emit smoke particles behind the bullet
        local dirX = -bullet.speedX / math.sqrt(bullet.speedX^2 + bullet.speedY^2)
        local dirY = -bullet.speedY / math.sqrt(bullet.speedX^2 + bullet.speedY^2)
        Smoke.emit(bullet.x, bullet.y, dirX, dirY, 2, bullet.stats.damage)

        -- Check for collision with bricks
        if bullet.y >= 0 then
            local hitBrick = false
            for _, brick in ipairs(bricks) do
                if not brick.destroyed and not brick.hitLastFrame then
                    if bullet.x + bullet.radius > brick.x and bullet.x - bullet.radius < brick.x + brick.width and
                        bullet.y + bullet.radius > brick.y and bullet.y - bullet.radius < brick.y + brick.height then

                        local damage = math.min(bullet.stats.damage, brick.health)
                        -- Deal damage to the brick
                        local kill = dealDamage(bullet, brick)
                          -- Handle explosive bullets
                        if Player.perks.explosiveBullets then
                            -- Create explosion effect
                            local scale = ( (Player.bonuses.range or 0) + (Player.permanentUpgrades.range or 0) + 1) * 0.2
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
            table.insert(deadBullets, bullet)
            table.remove(bullets, i)
        end

        ::continue::
    end
end

local laserAlpha = {a = 0}
local function laserShoot()
    unlockedBallTypes["Laser"].currentChargeTime = 0
    laserAlpha.a = 1
    local laserTween = tween.new(0.5, laserAlpha, {a = 0}, tween.inQuad)
    addTweenToUpdate(laserTween)
    for _, brick in ipairs(bricks) do
        if not brick.destroyed and brick.y > -brickHeight then
            if paddle.x < brick.x + brick.width and paddle.x + paddle.width > brick.x then
                dealDamage({stats = {damage = unlockedBallTypes["Laser"].stats.damage}, speedX = 0, speedY = -1}, brick)
            end
        end
    end
end

local function drawBalls()
    for _, ball in ipairs(Balls) do
        -- Draw the trail
        local ballColor = ballList[ball.name].color or {1,1,1,1}
        if not ball.dead then
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
        end

        -- Draw the ball
        love.graphics.circle("fill", ball.x, ball.y, ball.radius * ball.drawSizeBoost)
    end
end

local function drawBullets()
    -- Draw the smoke particles first (behind bullets)
    Smoke.draw()
    -- Draw the bullets themselves
    love.graphics.setColor(1, 1, 1, 1)
    for _, bullet in ipairs(bullets) do
        local scale = math.max(0.5, math.min(2.5, bullet.stats.damage * 0.1))
        local radius = (bullet.radius or 5) * scale
        love.graphics.circle("fill", bullet.x, bullet.y, radius)
    end
    -- Draw fading trails for dead bullets
    for _, bullet in ipairs(deadBullets) do
        if bullet.trailFade then
            love.graphics.setColor(1, 1, 1, bullet.trailFade * 0.5)
            love.graphics.circle("fill", bullet.x, bullet.y, (bullet.radius or 5) * 0.05)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

local function techDraw()
    if unlockedBallTypes["Laser"] then
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.rectangle("fill", paddle.x, 0, 1, paddle.y)
        love.graphics.rectangle("fill", paddle.x + paddle.width, 0, 1, paddle.y)
        --Shoot the laser
        laserShoot()
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
        if not ball.dead then
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
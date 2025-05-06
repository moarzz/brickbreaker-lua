--This file holds the values for all the Balls in the game.
-- It also holds the functions for updating the Balls and drawing them.

local Balls = {}
local ballCategories = {}
local ballList = {}
function Balls.getBallList()
    return ballList
end
local unlockedBallTypes = {}
local nextBallPrice = 10
function Balls.getNextBallPrice()
    return nextBallPrice
end
function Balls.NextBallPriceIncrease()
    nextBallPrice = nextBallPrice * 10
end

function Balls.getUnlockedBallTypes()
    return unlockedBallTypes
end

local ballTrainLength = 20 -- Length of the ball trail
local bullets = {}
local bulletSpeed = 500

local function shoot(gunName)
    if unlockedBallTypes[gunName] then
        local gun = unlockedBallTypes[gunName]
        if gun.currentAmmo > 0 then
            local speedOffset = paddle.currentSpeedX or 0
            gun.currentAmmo = gun.currentAmmo - 1  -- Decrease ammo count
            local speedXref = math.random(-100, 100) + speedOffset
            table.insert(bullets, {
                x = paddle.x + paddle.width / 2,
                y = paddle.y,
                speedX = speedXref,
                speedY = -math.sqrt(bulletSpeed^2 - speedXref^2),
                radius = 5,
                stats = {damage = gun.stats.damage}
            })
            Timer.after(2.0/gun.stats.fireRate, function() shoot(gunName) end)
        else
            gun.currentAmmo = gun.stats.ammo -- Reset ammo using the stats value
            Timer.after(gun.stats.cooldown, function() shoot(gunName) end)
        end
    else 
        print("Error: gun is not unlocked but shoot is being called.")
    end
end

--list of all ball types in the game
local function ballListInit()
    ballList = {
        baseBall = {
            name = "baseBall",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            startingPrice = 1,
            rarity = "common",
            description = "The most basic ball, it has no special abilities.",
            color = {1, 1, 1, 1}, -- White color
            stats = {
                speed = 250,
                damage = 1,
                cooldown = 3,
            },
        },
        fireBall = {
            name = "fireBall",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 2,
            description = "A ball that explodes on impact, dealing damage to nearby bricks.",
            color = {1, 0, 0, 1}, -- Red color
            stats = {
                speed = 100,
                damage = 2,
                cooldown = 3,
                range = 2
            },
        },
        phantomBall = {
            name = "phantomBall",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 2,
            rarity = "rare",
            startingPrice = 5,
            description = "A ball that can pass through bricks.",
            color = {0.5, 0.5, 0.7, 0.6}, -- Blue color
            stats = {
                speed = 50,
                damage = 1,
                cooldown = 3,
                range = 1
            },
        },
        goldBall = {
            name = "goldBall",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 10,
            description = "Hits brick : gives money equal to 2 times this ball's damage stat. Deals no damage",
            color = {1, 0.84, 0, 1},
            stats = {
                speed = 100,
                damage = 1,
                cooldown = 3,
            },
        },
        ["Damage boost ball"] = {
            name = "Damage boost ball",
            type = "ball",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 10,
            description = "Boost nearby ball damage by this ball's damage stat",
            stats = {
                speed = 75,
                damage = 1,
                cooldown = 3,
                range = 4
            },
        },
        machineGun = {
            name = "machineGun",
            type = "gun",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            rarity = "uncommon",
            startingPrice = 3,
            description = "fire bullets that die on impact in bursts",
            onBuy = function() 
                shoot("machineGun")
            end,
            noAmmount = true,
            currentAmmo = 5,

            stats = {
                damage = 1,
                cooldown = 5,
                pierce = 1,
                ammo = 5,
                fireRate = 8,
            },
        },
        Laser = {
            name = "Laser",
            type = "Special weapon",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            charging = true,
            currentChargeTime = 0,
            noAmmount = true,
            rarity = "rare",
            startingPrice = 10,
            description = "Paddle shoots laser beam forward equal to it's width that pierces bricks with a slow cooldown." .. 
            "\n\n when a ball bounces off the paddle, the laser's cooldown is charged by 5 second",
            color = {0, 1, 0, 1}, -- Green color
            stats = {
                damage = 1,
                cooldown = 10,
            },
        },
    }
    for _, ball in pairs(ballList) do
        ball.radius = ball.size*10 -- Set the radius based on size
    end
    print("Ball list initialized with " .. #ballList .. " ball types.")
end

-- calls ballListInit and adds a ball to it
function Balls.initialize()
    ballCategories = {}
    ballList = {}
    unlockedBallTypes = {}
    ballListInit()
    Balls.addBall("baseBall")
end

function Balls.addBall(ballName)
    ballName = ballName or "baseBall" -- Default to baseBall if no name is provided
    print("Adding ball: " .. ballName)

    local isNewBall = true
    for _, ball in ipairs(Balls) do
        if ball.name == ballName then
            isNewBall = false -- Ball already exists in the list
        end
    end

    local stats = nil
    local ballTemplate = ballList[ballName]
    if ballTemplate then -- makes sure there is a ball with ballName in ballList
        print("isNewBall: " .. tostring(isNewBall))
        if isNewBall then
            local newBallType = {
                name = ballName, -- Set the name of the ball
                ammount = 1, -- Set the initial amount to 1
                noAmmount = ballTemplate.noAmmount or false, -- Set noAmmount to false if not specified
                charging = true,
                currentChargeTime = 0,
                price = ballTemplate.startingPrice, -- Set the initial price of ball upgrades
                currentAmmo = ballTemplate.currentAmmo or {}, -- Copy specific values from the template
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
                    ballType.ammount = ballType.ammount + 1 -- Increase the amount of the ball in the list
                    break -- Exit the loop once the ball type is found
                end
            end
        end
        if not stats then
            print("Error: Ball type '" .. ballName .. "' not found in unlockedBallTypes. But, " .. ballName .. " is not a new ball")
            return
        end
        if ballTemplate.type == "ball" then
            local newBall = {
                name = ballTemplate.name,
                x = ballTemplate.x,
                y = ballTemplate.y,
                radius = ballTemplate.radius,
                drawSizeBoost = 1,
                drawSizeBoostTweens = {},
                currentlyOverlappingBricks = {},
                stats = stats,
                speedX = math.random(ballTemplate.stats.speed*0.6, ballTemplate.stats.speed*0.6), -- Randomize speedX
                speedY = 0, -- Will be calculated below
                dead = false,
                trail = {} -- Add a trail field to store previous positions
            }
            newBall.speedY = math.sqrt(newBall.stats.speed^2 - newBall.speedX^2) -- Calculate speedY
            table.insert(Balls, newBall)
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

--increases the particular stat of every ball of a certain type by set amount
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
    local hitTween = tween.new(0.05, ball, {drawSizeBoost = 2}, tween.outQuad)
    addTweenToUpdate(hitTween)
    table.insert(ball.drawSizeBoostTweens, hitTween.id) -- Store the tween in the ball's drawSizeBoostTweens table
    Timer.after(0.05, function()
        local hitTweenBack = tween.new(0.2, ball, {drawSizeBoost = 1}, tween.outQuad)
        addTweenToUpdate(hitTweenBack)
        table.insert(ball.drawSizeBoostTweens, hitTweenBack.id)
    end)
end

local function dealDamage(ball, brick)
    local damage = ball.stats.damage
    if unlockedBallTypes["Damage boost ball"] then
        for _, ballB in ipairs(Balls) do
            if ballB.name == "Damage boost ball" and ballB ~= ball then
                if isBrickInRange(brick, ballB.x, ballB.y, ballB.stats.range * 40) then
                    damage = damage + ballB.stats.damage
                end
            end
        end
    end
    if ball.name == "goldBall" then
        damage = damage * 2 -- Double the damage for goldBal
        damageNumber(damage, brick.x + brick.width / 2, brick.y + brick.height / 2, {1, 1, 0, 1}) -- Yellow color for goldBall
    else
        local damage = math.min(damage, brick.health)
        --deals damage to brick
        brick.health = brick.health - damage

        damageNumber(damage, brick.x + brick.width / 2, brick.y + brick.height / 2, {1, 0, 0, 1}) -- Red color for normal damage

        damageThisFrame = damageThisFrame + damage -- Increase the damage dealt this frame

        if brick.health >= 1 then
            brick.hitLastFrame = true
            brick.color = brick.health > 12 and {1, 1, 1, 1} or brickColorsByHealth[brick.health]
            local colorBeforeHit = brick.color or {1, 1, 1, 1} -- Default to white if no color is set
            brick.color = {1,1,1,1}
            local hitTweenBack = tween.new(0.35, brick, {color = colorBeforeHit}, tween.outSine)
            addTweenToUpdate(hitTweenBack)
        else
            brick.destroyed = true
            brick = nil
        end
        Player.score = Player.score + damage -- Increase player score based on damage dealt
    end
    if Player.bonuses.moneyIncome then
        Player.gain(1 + damage * (Player.bonuses.moneyIncome / 100)) -- Increase player money based on damage dealt
    else
        Player.gain(damage) -- Increase player money based on damage dealt
    end
end

local function brickCollisionEffects(ball, brick)
    if ball.name ~= "phantomBall" then
        ballHitVFX(ball) -- Call the ball hit VFX function
    end
    if ball.name == "fireBall" then
        local explosionImage = love.graphics.newImage("assets/VFX/explosion.png")
        createSpriteAnimation(ball.x, ball.y, ball.stats.range*2, explosionImage, 19, 19, 0.1)
        local bricksTouchingCircle = getBricksTouchingCircle(ball.x, ball.y, (ball.stats.range*2) * 10)
        if #bricksTouchingCircle > 1 then
        end
        for _, touchingBrick in ipairs(bricksTouchingCircle) do
            dealDamage(ball, touchingBrick) -- Deal damage to the touched bricks
        end
    else dealDamage(ball, brick) -- For other ball types, just deal damage to the brick
    end
end

local function brickCollision(ball, bricks, Player)
    local hitAnyBrick = false
    
    -- Special handling for phantom ball - needs to check ALL bricks
    if ball.name == "phantomBall" or ball.name == "Damage boost ball" then
        -- First, create a table to track bricks we're currently overlapping with
        local currentlyOverlappingBricks = {}

        for index, brick in ipairs(bricks) do
            if not brick.destroyed then
                local wasOverlaping = ball.currentlyOverlappingBricks[index] or false
                if wasOverlaping == true then
                    if not (ball.x + ball.radius * ball.stats.range > brick.x and ball.x - ball.radius * ball.stats.range < brick.x + brick.width and
                    ball.y + ball.radius * ball.stats.range > brick.y and ball.y - ball.radius * ball.stats.range < brick.y + brick.height) then
                        ball.currentlyOverlappingBricks[index] = nil -- Remove from currently overlapping if not overlapping anymore
                    end
                else
                    -- Check if we're currently overlapping with this brick
                    if ball.x + ball.radius * ball.stats.range > brick.x and ball.x - ball.radius * ball.stats.range < brick.x + brick.width and
                    ball.y + ball.radius * ball.stats.range > brick.y and ball.y - ball.radius * ball.stats.range < brick.y + brick.height then
                        ball.currentlyOverlappingBricks[index] = true
                        if ball.name == "phantomBall" then
                            dealDamage(ball, brick) -- Deal damage for new overlaps
                            -- If this brick wasn't in our last frame overlaps, it's a new entry
                            hitAnyBrick = true
                        end
                    end
                end
            end
        end
        if ball.name == "phantomBall" then
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
                
                brickCollisionEffects(ball, brick)
                return true
            end
        end
    end
    return false
end

local function paddleCollision(ball, paddle)
    if ball.x + ball.radius > paddle.x and ball.x - ball.radius < paddle.x + paddle.width and ball.speedY > 0 and
       ball.y + ball.radius > paddle.y and ball.y - ball.radius < paddle.y + paddle.height and ball.speedY >= 0 then
        playSoundEffect(paddleBoopSFX, 0.8, 1, false, true)
        ball.speedY = -ball.speedY
        local hitPosition = (ball.x - (paddle.x - ball.radius)) / (paddle.width + ball.radius * 2)
        ball.speedX = (hitPosition - 0.5) * 2 * math.abs(ball.stats.speed * 0.99)
        ball.speedY = math.sqrt(ball.stats.speed^2 - ball.speedX^2) * (ball.speedY > 0 and 1 or -1)
        if unlockedBallTypes["Laser"] then
            unlockedBallTypes["Laser"].currentChargeTime = unlockedBallTypes["Laser"].currentChargeTime + 2 -- Reset charge time
        end
    end
    return false
end

local function wallCollision(ball)
    if ball.x - ball.radius < statsWidth and ball.speedX < 0 then
        ball.speedX = -ball.speedX
        ball.x = statsWidth + ball.radius -- Ensure the ball is not stuck in the wall
        if ball.y < screenWidth then
            playSoundEffect(wallBoopSFX, 0.5, 0.5)
        end
    elseif ball.x + ball.radius > screenWidth - statsWidth and ball.speedX > 0 then
        ball.speedX = -ball.speedX
        ball.x = screenWidth - statsWidth - ball.radius -- Ensure the ball is not stuck in the wall
        if ball.y < screenWidth then
            playSoundEffect(wallBoopSFX, 0.5, 0.5)
        end
    end
    if ball.y - ball.radius < 0 and ball.speedY < 0 then
        ball.speedY = -ball.speedY
        ball.y = ball.radius -- Ensure the ball is not stuck in the wall
        playSoundEffect(wallBoopSFX, 0.5, 0.5)
    end
end

local function laserChargeUpdate(dt)
    if unlockedBallTypes["Laser"] then
        if unlockedBallTypes["Laser"].charging then
            unlockedBallTypes["Laser"].currentChargeTime = unlockedBallTypes["Laser"].currentChargeTime + dt
        end
    end
end

function Balls.update(dt, paddle, bricks)
    -- Store paddle reference for Ballspawn
    paddleReference = paddle
    for _, ball in ipairs(Balls) do -- Corrected loop
        -- Ball movement
        if Player.bonuses.ballSpeed then
            ball.x = ball.x + ball.speedX * (1 + Player.bonuses.ballSpeed/100) * dt
            ball.y = ball.y + ball.speedY * (1 + Player.bonuses.ballSpeed/100) * dt
        else
            ball.x = ball.x + ball.speedX * dt
            ball.y = ball.y + ball.speedY * dt
        end

        -- Update the trail
        table.insert(ball.trail, {x = ball.x, y = ball.y})
        if #ball.trail > ballTrainLength then -- Limit the trail length to 10 points
            table.remove(ball.trail, 1)
        end

        -- Ball collision with paddle
        paddleCollision(ball, paddle)

        -- Ball collision with bricks
        local hitBrickThisFrame = brickCollision(ball, bricks, Player)

        -- Ball collision with walls
        if not hitBrickThisFrame then
            wallCollision(ball)
        end

        -- Reset ball if it falls below the screen
        if ball.y - ball.radius > screenHeight then
            ballDie(ball)
        end
    end

    for i, bullet in ipairs(bullets) do
        bullet.x = bullet.x + bullet.speedX * dt
        bullet.y = bullet.y + bullet.speedY * dt

        -- Check for collision with bricks
        for _, brick in ipairs(bricks) do
            if not brick.destroyed and not brick.hitLastFrame then
                if bullet.x + bullet.radius > brick.x and bullet.x - bullet.radius < brick.x + brick.width and
                    bullet.y + bullet.radius > brick.y and bullet.y - bullet.radius < brick.y + brick.height then

                    -- Deal damage to the brick and remove the bullet
                    dealDamage(bullet, brick)
                    bullet = nil
                    table.remove(bullets, i)
                    return
                end
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
        if bullet.y - bullet.radius > screenHeight or bullet.y <= 0 then
            table.remove(bullets, i)
        end
    end

    -- Update laser charge time if it is unlocked
    laserChargeUpdate(dt)
end

local laserAlpha = {a = 0}

local function laserShoot()
    unlockedBallTypes["Laser"].currentChargeTime = 0
    laserAlpha.a = 1
    local laserTween = tween.new(0.5, laserAlpha, {a = 0}, tween.inQuad)
    addTweenToUpdate(laserTween)
    for _, brick in ipairs(bricks) do
        if not brick.destroyed then
            if paddle.x < brick.x + brick.width and paddle.x + paddle.width > brick.x then
                dealDamage({stats = {damage = unlockedBallTypes["Laser"].stats.damage}}, brick)
            end
        end
    end
end

local function LaserDraw()
    if unlockedBallTypes["Laser"] then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("fill", paddle.x, 0, 1, paddle.y)
        love.graphics.rectangle("fill", paddle.x + paddle.width, 0, 1, paddle.y)

        if unlockedBallTypes["Laser"].charging then 
            local chargeRatio = unlockedBallTypes["Laser"].currentChargeTime / unlockedBallTypes["Laser"].stats.cooldown
            if chargeRatio >= 1 then
                --Shoot the laser
                laserShoot()
            end

            love.graphics.setColor(0.5, 0.5, 0.5, 0.25)
            love.graphics.rectangle("fill", paddle.x + (paddle.width/2) - (paddle.width/2) * chargeRatio, 0, 1, paddle.y)
            love.graphics.rectangle("fill", paddle.x + (paddle.width/2)+ (paddle.width/2) * chargeRatio, 0, 1, paddle.y)

            --draw the laser
            love.graphics.setColor(0,1,0,laserAlpha.a) -- Red color for the laser
            love.graphics.rectangle("fill", paddle.x, 0, paddle.width, paddle.y)
        end
    end
end

function Balls.draw()
    -- Set line style and join to make the trail smoother
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")
    love.graphics.setLineWidth(1.0)

    for _, ball in ipairs(Balls) do
        -- Draw the trail
        if not ball.dead then
            for i = 1, #ball.trail - 1 do
                local p1 = ball.trail[i]
                local p2 = ball.trail[i + 1]
                love.graphics.setColor(1, 1, 1, i / #ball.trail) -- Fade the trail
                love.graphics.line(p1.x, p1.y, p2.x, p2.y)
            end
        end

        if ball.name == "Damage boost ball" then
            love.graphics.setColor(1, 0, 0, 1) -- Red color for damage boost ball
            drawImageCentered(auraImg, ball.x, ball.y, ball.stats.range * 80, ball.stats.range * 80) -- Draw the aura image
        end

        if ball.name == "phantomBall" then
            love.graphics.setColor(0, 0, 1, 1)
            drawImageCentered(auraImg, ball.x, ball.y, ball.stats.range * 40, ball.stats.range * 40) -- Draw the aura image
        end

        -- Draw the ball
        love.graphics.setColor(ballList[ball.name].color or {1,1,1,1}) -- Set color based on ball type
        love.graphics.circle("fill", ball.x, ball.y, ball.radius * ball.drawSizeBoost)

    end
    
    for _, bullet in ipairs(bullets) do
        love.graphics.setColor(1, 1, 0, 1) -- Yellow color for bullets
        love.graphics.circle("fill", bullet.x, bullet.y, bullet.radius)
    end

    LaserDraw()
end

return Balls
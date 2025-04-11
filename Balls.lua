--This file holds the values for all the Balls in the game.
-- It also holds the functions for updating the Balls and drawing them.

local Balls = {}
local ballCategories = {}
local ballList = {}

--list of all ball types in the game
local function ballListInit()
    ballList = {
        baseBall = {
            name = "baseBall",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 1,
            stats = {
                speed = 250,
                baseDamage = 1,
                cooldown = 3,
            },
        },
        fireBall = {
            name = "fireBall",
            x = screenWidth / 2,
            y = screenHeight / 2,
            size = 2,
            stats = {
                speed = 175,
                baseDamage = 2,
                cooldown = 3,
            },
        }
    }
    for _, ball in pairs(ballList) do
        ball.radius = ball.size*10 -- Set the radius based on size
    end
end

-- calls ballListInit and adds a ball to it
function Balls.initialize()
    ballListInit()
    Balls.addBall("baseBall") -- Add the first ball to the list
end

function Balls.addBall(ballName)
    ballName = ballName or "baseBall" -- Default to baseBall if no name is provided
    local ballTemplate = ballList[ballName]

    local newBall = true
    for _, ball in ipairs(Balls) do
        if ball.name == ballName then
            newBall = false -- Ball already exists in the list
        end
    end

    if ballTemplate then -- makes sure there is a ball with ballName in ballList
        -- Create a copy of the ball template
        local newBall = {
            x = ballTemplate.x,
            y = ballTemplate.y,
            radius = ballTemplate.radius,
            stats = ballTemplate.stats,	
            speedX = math.random(ballTemplate.stats.speed*0.6, ballTemplate.stats.speed*0.6), -- Randomize speedX
            speedY = 0, -- Will be calculated below
            dead = false,
            trail = {} -- Add a trail field to store previous positions
        }
        newBall.speedY = math.sqrt(newBall.stats.speed^2 - newBall.speedX^2) -- Calculate speedY
        table.insert(Balls, newBall)
        if newBall then
            local newCategory = {ammount = 1, ballName = ballName}
            table.insert(ballCategories, ballName) -- Add the new ball to the ballCategories list
        else 
            BallCategories[ballName].ammount = BallCategories[ballName].ammount + 1 -- Increase the amount of the ball in the list
        end
    else
        print("Error: Ball type '" .. ballName .. "' does not exist in ballList.")
    end
end

function Balls.damageIncrease(damage, ball)
    ball.stats.baseDamage = ball.stats.baseDamage + damage
end

--increases the particular stat of every ball of a certain type by set amount
function Balls.adjustSpeed(ballName)
    for _, ball in ipairs(Balls) do
        if ball.name == ballName then
            print("old ball speed : " .. ball.speedX .. ", " .. ball.speedY)
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
    ball.x = paddle.x + paddle.width / 2
    ball.y = paddle.y - paddle.height - ball.radius
    ball.speedX = math.random(-200, 200)
    ball.speedY = -math.sqrt(ball.stats.speed^2 - ball.speedX^2)
    ball.dead = false
    print("Ball spawned at: " .. ball.x .. ", " .. ball.y)
end

-- Function to handle ball death when it falls below the screen
local function ballDie(ball)
    if not ball.dead then
        ball.dead = true
        Timer.after(ball.stats.cooldown, function() Ballspawn(ball) end)
    end
end

local function brickCollision(ball, bricks, Player)
    for index, brick in ipairs(bricks) do
        if brick.hitLastFrame then
            brick.hitLastFrame = false
        elseif not brick.destroyed then
            if ball.x + ball.radius > brick.x and ball.x - ball.radius < brick.x + brick.width and
               ball.y + ball.radius > brick.y and ball.y - ball.radius < brick.y + brick.height then
                Player:gainXP(1)

                local dx = ball.x - (brick.x + brick.width / 2)
                local dy = ball.y - (brick.y + brick.height / 2)

                if math.abs(dx) * (30 + ball.radius) > math.abs(dy) * (75 + ball.radius) then
                    ball.speedX = -ball.speedX
                else
                    ball.speedY = -ball.speedY
                end

                if brick.health > 1 then
                    brick.health = brick.health - 1
                    brick.hitLastFrame = true
                    brick.color = brick.health > 12 and {1, 1, 1, 1} or brickColorsByHealth[brick.health]
                else
                    table.remove(bricks, index)
                    brick.destroyed = true
                end
                return true -- Collision detected with a brick
            end
        end
    end
    return false -- No collision with any bricks
end

local function paddleCollision(ball, paddle)
    if ball.x + ball.radius > paddle.x and ball.x - ball.radius < paddle.x + paddle.width and ball.speedY > 0 and
       ball.y + ball.radius > paddle.y and ball.y - ball.radius < paddle.y + paddle.height and ball.speedY >= 0 then
        ball.speedY = -ball.speedY
        local hitPosition = (ball.x - (paddle.x - ball.radius)) / (paddle.width + ball.radius * 2)
        ball.speedX = (hitPosition - 0.5) * 2 * math.abs(ball.stats.speed * 0.99)
        ball.speedY = math.sqrt(ball.stats.speed^2 - ball.speedX^2) * (ball.speedY > 0 and 1 or -1)
    end
    return false
end

local function wallCollision(ball)
    if ball.x - ball.radius < statsWidth and ball.speedX < 0 then
        ball.speedX = -ball.speedX
    elseif ball.x + ball.radius > screenWidth and ball.speedX > 0 then
        ball.speedX = -ball.speedX
    end
    if ball.y - ball.radius < 30 then
        ball.speedY = -ball.speedY
    end
end

function Balls.update(dt, paddle, bricks, Player)
    -- Store paddle reference for Ballspawn
    paddleReference = paddle

    for _, ball in ipairs(Balls) do -- Corrected loop
        -- Ball movement
        ball.x = ball.x + ball.speedX * dt
        ball.y = ball.y + ball.speedY * dt

        -- Update the trail
        table.insert(ball.trail, {x = ball.x, y = ball.y})
        if #ball.trail > 15 then -- Limit the trail length to 10 points
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
end

function Balls.draw()
    -- Set line style and join to make the trail smoother
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")
    --love.graphics.setLineWidth(2) -- Set the line width to 2 pixels

    for _, ball in ipairs(Balls) do
        -- Draw the trail
        for i = 1, #ball.trail - 1 do
            local p1 = ball.trail[i]
            local p2 = ball.trail[i + 1]
            love.graphics.setColor(1, 1, 1, i / #ball.trail) -- Fade the trail
            love.graphics.line(p1.x, p1.y, p2.x, p2.y)
        end

        -- Draw the ball
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
        love.graphics.circle("fill", ball.x, ball.y, ball.radius)
    end
end

return Balls
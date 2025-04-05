local Timer = require("Libraries.timer")

--This file holds the values for all the balls in the game.
-- It also holds the functions for updating the balls and drawing them.

local Balls = {}

function ballList(screenWidth, screenHeight)
    local ballList = {
        baseBall = {
            x = screenWidth / 2,
            y = screenHeight / 2,
            radius = 10,
            speed = 375,
            baseDamage = 1,
            cooldown = 5,
            currentCooldown = 5,
            speedX = math.random(-200, 200),
            speedY = 0 -- Will be calculated below
        }
    }
end

function Balls.initialize(screenWidth, screenHeight)
    ballList(screenWidth, screenHeight)
    -- create a table to hold all the ball templates

    local balls = {}
    table.insert(balls, {
        x = screenWidth / 2,
        y = screenHeight / 2,
        radius = 10,
        speed = 375,
        baseDamage = 1,
        cooldown = 3,
        speedX = math.random(-200, 200),
        speedY = 0, -- Will be calculated below
        dead = false
    })
    balls[1].speedY = math.sqrt(balls[1].speed^2 - balls[1].speedX^2)
    return balls
end

--Spawns the ball back at the bottom of the speed with a random speed
local function ballSpawn(ball)
    ball.x = paddle.x
    ball.y = paddle.y - paddle.height - ball.radius
    ball.speed = 280
    ball.speedX = math.random(-200, 200)
    ball.speedY = -math.sqrt(ball.speed^2 - ball.speedX^2)
    ball.dead = false
end

-- Function to handle ball death when it falls below the screen
local function ballDie(ball)
    ball.dead = true
    Timer.after(ball.cooldown, function() ballSpawn(ball) end)
end

function Balls.update(balls, dt, paddle, bricks, screenWidth, screenHeight, Player)
    -- Store paddle reference for ballSpawn
    paddleReference = paddle
    
    local ball = balls[1]

    if ball.dead then
        return -- Skip update if the ball is dead
    end
    -- Ball movement
    ball.x = ball.x + ball.speedX * dt
    ball.y = ball.y + ball.speedY * dt

    -- Ball collision with paddle
    if ball.x + ball.radius > paddle.x and ball.x - ball.radius < paddle.x + paddle.width and ball.speedY > 0 and
       ball.y + ball.radius > paddle.y and ball.y - ball.radius < paddle.y + paddle.height and ball.speedY >= 0 then
        ball.speedY = -ball.speedY
        local hitPosition = (ball.x - (paddle.x - ball.radius)) / (paddle.width + ball.radius * 2)
        ball.speedX = (hitPosition - 0.5) * 2 * math.abs(ball.speed * 0.99)
        ball.speedY = math.sqrt(ball.speed^2 - ball.speedX^2) * (ball.speedY > 0 and 1 or -1)
    end

    -- Ball collision with bricks
    local hitBrickThisFrame = false
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
                hitBrickThisFrame = true
                break
            end
        end
    end

    -- Ball collision with walls
    if not hitBrickThisFrame then
        if ball.x - ball.radius < 0 and ball.speedX < 0 then
            ball.speedX = -ball.speedX
        elseif ball.x + ball.radius > screenWidth and ball.speedX > 0 then
            ball.speedX = -ball.speedX
        end
        if ball.y - ball.radius < 30 then
            ball.speedY = -ball.speedY
        end
    end

    -- Reset ball if it falls below the screen
    if ball.y - ball.radius > screenHeight then
        ballDie(ball)
    end
end

function Balls.draw(balls)
    for _, ball in ipairs(balls) do
        love.graphics.circle("fill", ball.x, ball.y, ball.radius)
    end
end

return Balls
local UtilityFunction = require("UtilityFunction")
local Player = require("Player")
-- main.lua
-- Basic Brick Breaker Game

-- Load Love2D modules
function love.load()
    -- Screen dimensions
    screenWidth = 1020
    screenHeight = 600
    love.window.setMode(screenWidth, screenHeight)
    love.window.setTitle("Brick Breaker")

    -- Background image
    backgroundImage = love.graphics.newImage("assets/neonGrid.png")

    -- Paddle
    paddle = {
        x = screenWidth / 2 - 50,
        y = screenHeight - 30,
        width = 130,
        height = 20,
        speed = 400
    }

    -- Ball
    ball = {
        x = screenWidth / 2,
        y = screenHeight / 2,
        radius = 10,
        speed = 375
    }
    ball.speedX = math.random(-200, 200)
    ball.speedY = math.sqrt(ball.speed * ball.speed - ball.speedX * ball.speedX)

    -- Bricks
    brickColorsByHealth = {
        [1] = {UtilityFunction.HslaToRgba(60, 1, 0.5, 1)},
        [2] = {UtilityFunction.HslaToRgba(30, 0.92, 0.46, 1)},
        [3] = {UtilityFunction.HslaToRgba(0, 0.84, 0.42, 1)},
        [4] = {UtilityFunction.HslaToRgba(330, 0.76, 0.38, 1)},
        [5] = {UtilityFunction.HslaToRgba(300, 0.68, 0.34, 1)},
        [6] = {UtilityFunction.HslaToRgba(270, 0.6, 0.3, 1)},
        [7] = {UtilityFunction.HslaToRgba(240, 0.52, 0.26, 1)},
        [8] = {UtilityFunction.HslaToRgba(210, 0.44, 0.22, 1)},
        [9] = {UtilityFunction.HslaToRgba(180, 0.36, 0.18, 1)},
        [10] = {UtilityFunction.HslaToRgba(150, 0.28, 0.14, 1)},
        [11] = {UtilityFunction.HslaToRgba(120, 0.2, 0.1, 1)},
        [12] = {UtilityFunction.HslaToRgba(90, 0.12, 0.06, 1)}
    }
    bricks = {}
    brickSpacing = 10
    brickWidth = 75
    brickHeight = 30
    rows = 100
    cols = 10
    brickSpeed = 10 -- Speed at which bricks move down (pixels per second)
    currentRowPopulation = 1 -- Number of bricks in the first row

    -- Generate bricks
    for i = 0, rows - 1 do
        generateRow(currentRowPopulation, i * -(brickHeight + brickSpacing)) --generate 100 scaling rows of bricks
        currentRowPopulation = currentRowPopulation + 1
    end
end

function love.update(dt)
    -- Paddle movement
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        paddle.x = paddle.x - paddle.speed * dt
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        paddle.x = paddle.x + paddle.speed * dt
    end

    -- Keep paddle within screen bounds
    paddle.x = math.max(0, math.min(screenWidth - paddle.width, paddle.x))

    -- Ball movement
    ball.x = ball.x + ball.speedX * dt
    ball.y = ball.y + ball.speedY * dt

    -- Ball collision with paddle
    if ball.x + ball.radius > paddle.x and ball.x - ball.radius < paddle.x + paddle.width and ball.speedY > 0 and
    ball.y + ball.radius > paddle.y and ball.y - ball.radius < paddle.y + paddle.height then
        -- Reverse vertical speed
        ball.speedY = -ball.speedY

        -- Adjust horizontal speed direction based on where the ball hits the paddle
        local hitPosition = (ball.x - (paddle.x - ball.radius)) / (paddle.width + ball.radius * 2) -- Relative position (0 to 1)
        ball.speedX = (hitPosition - 0.5) * 2 * math.abs(ball.speed*0.99) -- Adjust direction
        ball.speedY = math.sqrt(ball.speed^2 - ball.speedX^2) * (ball.speedY > 0 and 1 or -1)
    end

    -- Ball collision with bricks
    hitBrickThisFrame = false
    for index_, brick in ipairs(bricks) do
        if brick.hitLastFrame then
            brick.hitLastFrame = false
        elseif not brick.destroyed then
            if ball.x + ball.radius > brick.x and ball.x - ball.radius < brick.x + brick.width and
               ball.y + ball.radius > brick.y and ball.y - ball.radius < brick.y + brick.height then

                -- Determine the side of collision
                local ballCenterX = ball.x
                local ballCenterY = ball.y
                local brickCenterX = brick.x + brick.width / 2
                local brickCenterY = brick.y + brick.height / 2

                local dx = ballCenterX - brickCenterX
                local dy = ballCenterY - brickCenterY

                if math.abs(dx)*(30 + ball.radius) > math.abs(dy)*(75 + ball.radius) then
                    -- Horizontal collision
                    ball.speedX = -ball.speedX
                else
                    -- Vertical collision
                    ball.speedY = -ball.speedY
                end
                if brick.health > 1 then
                    brick.health = brick.health - 1
                    brick.hitLastFrame = true
                    -- Update brick color based on health
                    if brick.health > 12 then --ca marche pour live mais je vais devoir le changer pour une fonction qui set la couleur selon une fonction sqrt
                        brick.color = {1,1,1,1}
                    else
                        brick.color = brickColorsByHealth[brick.health]
                    end
                else
                    table.remove(bricks, index)
                    -- Remove the brick from the table
                    brick.destroyed = true
                    print(#bricks)
                    hitBrickThisFrame = true
                    break
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
        ball.x = screenWidth / 2
        ball.y = screenHeight / 2
        ball.speed = 280
        ball.speedX = math.random(-200, 200)
        ball.speedY = math.sqrt(ball.speed * ball.speed - ball.speedX * ball.speedX)
    end

    -- Move bricks down
    for _, brick in ipairs(bricks) do
        if not brick.destroyed then
            brick.y = brick.y + brickSpeed * dt
        end
    end
end

function love.draw()
    -- Draw background image
    love.graphics.draw(backgroundImage, 0, 0, 0, screenWidth / backgroundImage:getWidth(), screenHeight / backgroundImage:getHeight())

    -- Draw paddle
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width, paddle.height)

    -- Draw ball
    love.graphics.circle("fill", ball.x, ball.y, ball.radius)

    -- Draw bricks
    for _, brick in ipairs(bricks) do
        if not brick.destroyed then
            --ensure brick color is valid
            local color = brick.color or {1, 1, 1, 1}
            love.graphics.setColor(color) -- set brick color
            love.graphics.rectangle("fill", brick.x, brick.y, brick.width, brick.height)
        end
    end

    -- Draw XP bar
    Player:drawXPBar(screenWidth, 30)
    love.graphics.setColor(1, 1, 1) -- reset color to white
end

--exit game with esc key
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function generateRow(brickCount, yPos)
    local row = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    for i = 1, brickCount do
        n = math.random(12)
        row[n] = row[n] + 1
    end
    for xPos, brickHealth in ipairs(row) do
        if brickHealth > 0 then
            local brickColor
            if brickHealth > 12 then --ca marche pour live mais je vais devoir le changer pour une fonction qui set la couleur selon une fonction sqrt
                brickColor = {1,1,1,1}
            else
                brickColor = brickColorsByHealth[brickHealth]
            end
            table.insert(bricks, {
                x = (xPos - 1) * (brickWidth + brickSpacing) + 5,
                y = yPos,
                width = brickWidth,
                height = brickHeight,
                destroyed = false,
                health = brickHealth,
                color = brickColor,
                hitLastFrame = false
            })
        end
    end
    return row
end
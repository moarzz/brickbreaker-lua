local UtilityFunction = require("UtilityFunction") -- utility functions
local Player = require("Player") -- player logic
local Balls = require("Balls") -- ball logic
local Timer = require("Libraries.timer") -- timer library
-- main.lua
-- Basic Brick Breaker Game

-- Load Love2D modules
function love.load()
    -- Load the MP3 file
    backgroundMusic = love.audio.newSource("assets/sounds/game song.mp3", "static")
    backgroundMusic:setLooping(true)
    backgroundMusic:play()

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

    -- Initialize balls
    balls = Balls.initialize(screenWidth, screenHeight)

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
    Timer.update(dt) -- Update the timer

    if not Player.levelingUp and not UtilityFunction.freeze then
        -- Paddle movement
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            paddle.x = paddle.x - paddle.speed * dt
        elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            paddle.x = paddle.x + paddle.speed * dt
        end

        -- Keep paddle within screen bounds
        paddle.x = math.max(0, math.min(screenWidth - paddle.width, paddle.x))

        -- Update balls
        Balls.update(balls, dt, paddle, bricks, screenWidth, screenHeight, Player)

        -- Move bricks down
        for _, brick in ipairs(bricks) do
            if not brick.destroyed then
                brick.y = brick.y + brickSpeed * dt
            end
        end
    end
end

function love.draw()
    -- Draw background image
    love.graphics.draw(backgroundImage, 0, 0, 0, screenWidth / backgroundImage:getWidth(), screenHeight / backgroundImage:getHeight())

    -- Draw paddle
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width, paddle.height)

    -- Draw balls
    Balls.draw(balls)

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

    if Player.levelingUp then
        Player:drawLevelUpShop()
    end
end

--exit game with esc key
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if key == "f" then
        UtilityFunction:toggleFreeze()
    end
    if key == "l" then
        Player:levelUp()
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
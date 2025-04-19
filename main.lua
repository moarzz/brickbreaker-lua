UtilityFunction = require("UtilityFunction") -- utility functions
Player = require("Player") -- player logic
Balls = require("Balls") -- ball logic
Timer = require("Libraries.timer") -- timer library
local upgradesUI = require("upgradesUI") -- upgrade UI logic
suit = require("Libraries.Suit") -- UI library
tween = require("Libraries.tween") -- tweening library
-- main.lua
-- Basic Brick Breaker Game

--screen dimensions
statsWidth = 450 -- Width of the stats area
screenWidth = 1020 + statsWidth
screenHeight = 1000

playRate = 1 -- Set the playback rate to 1 (normal speed)

local function generateRow(brickCount, yPos)
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
                x = statsWidth + (xPos - 1) * (brickWidth + brickSpacing) + 5,
                y = yPos,
                width = brickWidth,
                height = brickHeight,
                destroyed = false,
                health = brickHealth,
                color = brickColor,
                hitLastFrame = false
            })
            --print("screenWidth: " .. screenWidth)
        end
    end
    return row
end

function initializeBricks()
    -- Bricks
    brickColorsByHealth = {
        [1] = {HslaToRgba(60, 1, 0.5, 1)},
        [2] = {HslaToRgba(30, 0.92, 0.46, 1)},
        [3] = {HslaToRgba(0, 0.84, 0.42, 1)},
        [4] = {HslaToRgba(330, 0.76, 0.38, 1)},
        [5] = {HslaToRgba(300, 0.68, 0.34, 1)},
        [6] = {HslaToRgba(270, 0.6, 0.3, 1)},
        [7] = {HslaToRgba(240, 0.52, 0.26, 1)},
        [8] = {HslaToRgba(210, 0.44, 0.22, 1)},
        [9] = {HslaToRgba(180, 0.36, 0.18, 1)},
        [10] = {HslaToRgba(150, 0.28, 0.14, 1)},
        [11] = {HslaToRgba(120, 0.2, 0.1, 1)},
        [12] = {HslaToRgba(90, 0.12, 0.06, 1)}
    }
    bricks = {}
    brickSpacing = 10
    brickWidth = 75
    brickHeight = 30
    rows = 100
    cols = 10
    brickSpeed = { value = 10 } -- Speed at which bricks move down (pixels per second)
    currentRowPopulation = 1 -- Number of bricks in the first row

    -- Generate bricks
    for i = 0, rows - 1 do
        generateRow(currentRowPopulation, i * -(brickHeight + brickSpacing)) --generate 100 scaling rows of bricks
        currentRowPopulation = currentRowPopulation + 1
    end
end
-- Load Love2D modules
function love.load()
    -- Load the MP3 file
    backgroundMusic = love.audio.newSource("assets/sounds/game song.mp3", "static")
    backgroundMusic:setLooping(true)
    backgroundMusic:play()
    brickFont = love.graphics.newFont(14)

    -- Set fullscreen mode
    love.window.setMode(1920, 1080, {fullscreen = true, vsync = true})

    -- Get screen dimensions
    screenWidth, screenHeight = love.graphics.getDimensions()

    love.window.setTitle("Brick Breaker")

    -- Background image
    backgroundImage = love.graphics.newImage("assets/neonGrid.png")

    -- Paddle
    paddle = {
        x = screenWidth / 2 - 50,
        y = screenHeight - 200,
        width = 130,
        widthMult = 1,
        height = 20,
        speed = 400,
        speedMult = 1
    }

    -- Initialize Balls
    Balls.initialize() -- Removed screenWidth and screenHeight arguments

    initializeBricks()
    print("screenWidth: " .. screenWidth)
end

function love.update(dt)
    dt = dt * playRate -- Adjust the delta time based on the playback rate
    Timer.update(dt) -- Update the timer

    if not Player.levelingUp and not UtilityFunction.freeze then
        -- Paddle movement
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            paddle.x = paddle.x - paddle.speed * paddle.speedMult * dt
        elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            paddle.x = paddle.x + paddle.speed * paddle.speedMult * dt
        end

        -- Keep paddle within screen bounds
        paddle.x = math.max(statsWidth, math.min(screenWidth - statsWidth - paddle.width, paddle.x))

        -- Update Balls
        Balls.update(dt, paddle, bricks, Player) -- Removed screenWidth and screenHeight arguments

        
        -- Move bricks down
        for _, brick in ipairs(bricks) do
            if not brick.destroyed then
                brick.y = brick.y + brickSpeed.value * dt
            end
        end
    end

    explosionsUpdate(dt) -- Update explosions

    for _, brick in ipairs(bricks) do
        if brick.destroyed then
            table.remove(bricks, _)
        end
    end

    updateAllTweens(dt) -- Update all tweens

    Player.update(dt) -- Update player logic

    updateAnimations(dt) -- Update animations
end

local function drawBricks()
    setFont(14) -- Set the preloaded font once for all bricks

    for _, brick in ipairs(bricks) do
        if not brick.destroyed and brick.y > 0 - brick.height - 5 then
            -- Ensure brick color is valid
            local color = brick.color or {1, 1, 1, 1}
            love.graphics.setColor(color) -- Set brick color
            love.graphics.rectangle("fill", brick.x, brick.y, brick.width, brick.height)

            -- Draw the brick's HP using drawTextWithOutline
            local textColor = {1, 1, 1, 1} -- White text color
            local outlineColor = {0, 0, 0, 1} -- Black outline color
            local outlineThickness = 1
            local hpText = tostring(brick.health or 0)

            drawTextWithOutline(hpText, brick.x + brick.width / 2, brick.y + brick.height / 2, brickFont, textColor, outlineColor, outlineThickness)
        end
    end
end

local function drawStatsArea()
    -- Draw stats area background
    love.graphics.setColor(0.2, 0.2, 0.2, 1) -- Dark gray background
    love.graphics.rectangle("fill", 0, 0, statsWidth, screenHeight)

    love.graphics.rectangle("fill", screenWidth - statsWidth, 0, statsWidth, screenHeight)

    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white for other drawings
end

function love.draw()
    resetButtonLastID()-- resets the button ID to 1 so it stays consistent

    drawStatsArea() -- Draw the stats area
    love.graphics.setColor(1 , 1, 1, 0.25)
    love.graphics.rectangle("fill", statsWidth, paddle.y + paddle.height/2, screenWidth - statsWidth * 2, 1) -- Draw the background for the game area
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height) -- Draw paddle

    drawBricks() -- Draw bricks

    Balls.draw(Balls) -- Draw balls

    upgradesUI.draw()

    drawAnimations() -- Draw animations

    suit.draw() -- Draw the UI elements using Suit

    if Player.dead then
        GameOverDraw()
    end
    drawFPS()
end

--exit game with esc key and other debugging keys
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    if key == "f" then
        toggleFreeze()
    end
    if key == "b" then
        Balls.addBall()
    end
    if key == "p" then
        Balls.addBall("fireBall")
    end
    if key == "m" then
        Player.money = Player.money + 10000000000000000 -- Add 1000 money for testing
    end
    if key == "t" then
        getBricksTouchingCircle(50, 50, 50)
    end
    if key == "l" then
        playRate = playRate * 2
    end
    if key == "k" then 
        playRate = 1
    end
    if key == "j" then 
        playRate = playRate / 2
    end
    if key == "h" then 
        Player.hit()
    end
    if key == "g" then
        Player.die()
    end
end
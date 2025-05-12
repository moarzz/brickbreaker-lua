UtilityFunction = require("UtilityFunction") -- utility functions
Player = require("Player") -- player logic
Balls = require("Balls") -- ball logic
Timer = require("Libraries.timer") -- timer library
local upgradesUI = require("upgradesUI") -- upgrade UI logic
moonshine = require("Libraries.moonshine")
shaders = require("shaders") -- shader logic
suit = require("Libraries.Suit") -- UI library
tween = require("Libraries.tween") -- tweening library
VFX = require("VFX") -- VFX library

--screen dimensions
statsWidth = 450 -- Width of the stats area
screenWidth = 1020 + statsWidth
screenHeight = 1000

playRate = 1 -- Set the playback rate to 1 (normal speed)
gameCanvas = nil

-- shaders
local backgroundShader

local function generateRow(brickCount, yPos)
    local row = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    local rowOffset = mapRangeClamped(math.random(0,10),0,10, -brickWidth/2, brickWidth/2)
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
                id = #bricks + 1,
                x = statsWidth + (xPos - 1) * (brickWidth + brickSpacing) + 5 + rowOffset,
                y = yPos,
                drawOffsetX = 0,
                drawOffsetY = 0,
                drawOffsetRot = 0,
                drawScale = 1,
                width = brickWidth,
                height = brickHeight,
                destroyed = false,
                health = brickHealth,
                color = {brickColor[1], brickColor[2], brickColor[3], 1}, -- Set the color with full opacity
                hitLastFrame = false
            })
        end
    end
    return row
end

local function addMoreBricks()
    for i = #bricks, 0, -1 do
        if bricks[i] then
            if bricks[i].y > -50 then
                print("spawning more bricks")
                for i=1 , 10 do
                    generateRow(currentRowPopulation, i * -(brickHeight + brickSpacing) - 50) --generate 100 scaling rows of bricks
                    currentRowPopulation = currentRowPopulation + 1 + math.floor(currentRowPopulation/15)
                end
                return
            else 
                return
            end--else print("bricks are too high to spawn more") end
        end
    end
end

function initializeBricks()
    -- Bricks
    brickColorsByHealth = {
        [1] = {HslaToRgba(60, 1, 0.5, 1)},
        [2] = {HslaToRgba(45, 0.96, 0.48, 1)},
        [3] = {HslaToRgba(30, 0.92, 0.46, 1)},
        [4] = {HslaToRgba(15, 0.88, 0.44, 1)},
        [5] = {HslaToRgba(0, 0.84, 0.42, 1)},
        [6] = {HslaToRgba(330, 0.8, 0.4, 1)},
        [7] = {HslaToRgba(315, 0.76, 0.38, 1)},
        [8] = {HslaToRgba(300, 0.72, 0.36, 1)},
        [9] = {HslaToRgba(285, 0.68, 0.34, 1)},
        [10] = {HslaToRgba(270, 0.64, 0.32, 1)},
        [11] = {HslaToRgba(255, 0.6, 0.3, 1)},
        [12] = {HslaToRgba(240, 0.56, 0.28, 1)},
        [13] = {HslaToRgba(225, 0.52, 0.26, 1)},
        [14] = {HslaToRgba(210, 0.48, 0.24, 1)},
        [15] = {HslaToRgba(195, 0.44, 0.22, 1)},
        [16] = {HslaToRgba(180, 0.4, 0.2, 1)},
        [17] = {HslaToRgba(165, 0.36, 0.18, 1)},
        [18] = {HslaToRgba(150, 0.32, 0.16, 1)},
        [19] = {HslaToRgba(135, 0.28, 0.14, 1)},
        [20] = {HslaToRgba(120, 0.24, 0.12, 1)},
        [21] = {HslaToRgba(105, 0.2, 0.1, 1)},
        [22] = {HslaToRgba(90, 0.16, 0.08, 1)},
        [23] = {HslaToRgba(75, 0.12, 0.06, 1)},
        [24] = {HslaToRgba(60, 0.08, 0.04, 1)},
        [25] = {HslaToRgba(45, 0.04, 0.02, 1)},
        [26] = {HslaToRgba(30, 0, 0, 1)}

    }
    bricks = {}
    brickWidth = 75
    brickHeight = 30
    brickSpacing = 10 -- Spacing between bricks
    rows = 10
    cols = 10
    brickSpeed = { value = 10 } -- Speed at which bricks move down (pixels per second)
    currentRowPopulation = 1 -- Number of bricks in the first row

    -- Generate bricks
    for i = 0, rows - 1 do
        generateRow(currentRowPopulation, i * -(brickHeight + brickSpacing)) --generate 100 scaling rows of bricks
        currentRowPopulation = currentRowPopulation + 1 + math.floor(currentRowPopulation/50)
    end

    --check for adding more bricks every 0.5 seconds
    Timer.every(0.5, function() addMoreBricks() end)
end

local function loadAssets()
    --load images
    auraImg = love.graphics.newImage("assets/sprites/aura.png")
    brickImg = love.graphics.newImage("assets/sprites/brick.png")

    -- load sounds
    backgroundMusic = love.audio.newSource("assets/SFX/game song.mp3", "static")
    brickHitSFX = love.audio.newSource("assets/SFX/brickBoop.mp3", "static")
    paddleBoopSFX = love.audio.newSource("assets/SFX/paddleBoop.mp3", "static")
    wallBoopSFX = love.audio.newSource("assets/SFX/wallBoop.mp3", "static")
    explosionSFX = love.audio.newSource("assets/SFX/explosion.mp3", "static") -- Add explosion sound if available
    brickDeathSfX = love.audio.newSource("assets/SFX/brickDeath.mp3", "static")

    -- load shaders
    backgroundShader = love.graphics.newShader("Shaders/background.glsl")
    shaders.load()
end

-- Load Love2D modules
function love.load()
    dress = suit.new()

    loadAssets() -- Load assets

    -- Load the MP3 file
    playSoundEffect(backgroundMusic, 0.5, 1, true, false) -- Play the background music
    brickFont = love.graphics.newFont(14)

    -- Set fullscreen mode
    love.window.setMode(1920, 1080, {fullscreen = true, vsync = true})

    -- Get screen dimensions
    screenWidth, screenHeight = love.graphics.getDimensions()
    gameCanvas = love.graphics.newCanvas(screenWidth, screenHeight)
    glowCanvas = love.graphics.newCanvas(screenWidth, screenHeight)

    love.window.setTitle("Brick Breaker")

    -- Paddle
    paddle = {
        x = screenWidth / 2 - 50,
        y = screenHeight - 200,
        width = 130,
        widthMult = 1,
        height = 20,
        speed = 400,
        currrentSpeedX = 0,
        speedMult = 1
    }

    -- Initialize Balls
    Balls.initialize() -- Removed screenWidth and screenHeight arguments

    initializeBricks()
    print("screenWidth: " .. screenWidth)
end

local function getBrickSpeedMult()
    -- the lowest bricK}k on screen will have the highest Y.
    for i, brick in ipairs(bricks) do
        if not brick.destroyed then
            return mapRangeClamped(brick.y, 0, paddle.y - brickHeight, 2, 0.25)
        end
    end
    error("No bricks found that weren't destroyed")
end

local function moveBricksDown(dt)
    local speedMult = getBrickSpeedMult() -- Get the speed multiplier based on the lowest brick Y position
    for _, brick in ipairs(bricks) do
        if not brick.destroyed then
            brick.y = brick.y + brickSpeed.value * dt * speedMult
        end
    end
end

backgroundColor = {r=0,g=0,b=0,a=0}
screenOffset = {x=0,y=0}
function love.update(dt)

    --send info to background shader
    backgroundShader:send("time", love.timer.getTime())                    -- RAJOUTE UN "-STARTTIME"
    backgroundShader:send("resolution", {screenWidth, screenHeight})

    dt = dt * playRate -- Adjust the delta time based on the playback rate
    dt = dt * 0.4 -- ralenti le jeu a la bonne vitesse
    if UtilityFunction.freeze then
        dt = 0 -- Freeze the game if UtilityFunction.freeze is true
    end
    Timer.update(dt) -- Update the timer

    -- checks if game is frozen
    if not Player.levelingUp and not UtilityFunction.freeze then
        -- Paddle movement
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            paddle.x = paddle.x - paddle.speed * paddle.speedMult * dt
            paddle.currrentSpeedX = -400
        elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            paddle.x = paddle.x + paddle.speed * paddle.speedMult * dt
            paddle.currrentSpeedX = 400
        else paddle.currrentSpeedX = 0
        end

        -- Keep paddle within screen bounds
        paddle.x = math.max(statsWidth, math.min(screenWidth - statsWidth - paddle.width, paddle.x))

        -- Update Balls
        Balls.update(dt, paddle, bricks, Player) -- Removed screenWidth and screenHeight arguments

        
        -- Move bricks down
        moveBricksDown(dt)

        boomUpdate(dt) -- Update explosion for damage

        updateAllTweens(dt) -- Update all tweens

        Player.update(dt) -- Update player logic

        updateAnimations(dt) -- Update animations


        if damageThisFrame > 0 then
            damageScreenVisuals(0.25, damageThisFrame)
            playSoundEffect(brickHitSFX, mapRangeClamped(damageThisFrame, 1,10, 0.4,1.0), mapRangeClamped(damageThisFrame,1,10,0.5,1), false, true)
        end
        damageThisFrame = 0 -- Reset damage this frame
    end
end

function drawBricks()
    for _, brick in ipairs(bricks) do
        if not brick.destroyed and brick.y > 0 - brick.height - 5 then
            -- Ensure brick color is valid
            local color = brick.color or {1, 1, 1, 1}
            love.graphics.setColor(color) -- Set brick color
            love.graphics.draw(brickImg, brick.x + brick.drawOffsetX, brick.y + brick.drawOffsetY, brick.drawOffsetRot, brick.width / brickImg:getWidth(), brick.height / brickImg:getHeight())

            -- Calculate the origin for rotation (center of the brick)
            local originX = brick.width / 2
            local originY = brick.height / 2

            -- Draw the brick with rotation around its center
            love.graphics.draw(
                brickImg,
                brick.x + brick.drawOffsetX + originX, -- Adjust x position
                brick.y + brick.drawOffsetY + originY, -- Adjust y position
                brick.drawOffsetRot, -- Rotation angle
                brick.width / brickImg:getWidth(), -- Scale X
                brick.height / brickImg:getHeight(), -- Scale Y
                originX, -- Origin X (center of the brick)
                originY -- Origin Y (center of the brick)
            )

            --[[ Draw the brick's HP using drawTextWithOutline
            local textColor = {1, 1, 1, 1} -- White text color
            local outlineColor = {0, 0, 0, 1} -- Black outline color
            local outlineThickness = 1
            local hpText = tostring(brick.health or 0)

            setFont(14)
            drawTextWithOutline(hpText, brick.x + brick.width / 2, brick.y + brick.height / 2, textColor, outlineColor, outlineThickness)]]
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

    love.graphics.setCanvas(gameCanvas) -- Set the canvas for drawing
    love.graphics.clear()

    love.graphics.push()
    love.graphics.translate(screenOffset.x, screenOffset.y) -- Apply screen shake

    love.graphics.setShader(backgroundShader)
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
    love.graphics.setShader()

    drawBricks() -- Draw bricks

    Balls.draw(Balls) -- Draw balls

    --Draw paddle
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Reset color to white for paddle
    love.graphics.rectangle("fill", statsWidth, paddle.y, screenWidth - statsWidth*2, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", paddle.x, paddle.y, paddle.width * paddle.widthMult, paddle.height)

    drawDamageNumbers() -- Draw damage numbers

    drawAnimations() -- Draw animations
    

    love.graphics.pop()

    drawStatsArea() -- Draw the stats area
    
    upgradesUI.draw()

    -- Draw the UI elements using Suit
    suit.draw()
    dress:draw()

    love.graphics.setCanvas()

    shaders.draw()

    if Player.dead then
        GameOverDraw()
    end
    drawFPS()
end

local boopah = 1
boopag = 1
--exit game with esc key and other debugging keys
function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    -- freeze
    if key == "f" then
        toggleFreeze()
    end

    if key == "b" then
        damageNumber(4,screenWidth/2,screenHeight/2,{1,1,1,1})
    end

    --money manipulation
    if key == "m" then
        Player.money = Player.money + 10000000000000000 -- Add 1000 money for testing
    end
    if key == "n" then
        Player.money = 0
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

    -- reset
    if key == "r" then
        love.event.quit("restart")
    end

    --test damage screen visuals 
    if key == "g" then
        damageThisFrame = boopah
    end
    if key == "v" then
        boopah = boopah + 2
        boopag = boopag + 2
    end

    --test ball hit vfx
    if key == "y" then
        for _,ball in ipairs(Balls) do
            ballHitVFX(ball)
        end
    end

    --print brick speed mult calculation
    if key == "t" then
        local total = 0
        for _, ball in ipairs(Balls) do
            if ball.name == "Fire Ball" and ball.dead == false then
                total = total + 1
            end
        end
        print("total fireballs alive: " .. total)
    end

    if key == "=" then
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            for _, brick in ipairs(bricks) do
                if not brick.destroyed then
                    brick.health = brick.health + 1
                    brick.color = brickColorsByHealth[brick.health]
                end
            end
        else end
    end
    if key == "-" then
        for _, brick in ipairs(bricks) do
            if not brick.destroyed then
                brick.health = brick.health + 1
                brick.color = brickColorsByHealth[brick.health]
            end
        end
    end
end

function love.mousepressed(x, y, button)

end
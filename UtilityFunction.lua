-- filepath: c:\Users\xavie\OneDrive\Documents\GitHub\brickbreaker\UtilityFunction.lua
local UtilityFunction = {
    freeze = false -- Global freeze variable to control game state
}

function toggleFreeze()
    UtilityFunction.freeze = not UtilityFunction.freeze
    print("game is now " .. (UtilityFunction.freeze and "frozen" or "unfrozen"))
end

function restartGame()
    -- Reset Player
    Player.money = 0
    Player.lives = 3
    Player.dead = false
    Player.bonuses = {
        critChance = 0,
        moneyIncome = 0,
        ballSpeed = 0,
        paddleSpeed = 0,
        paddleSize = 0
    }

    Player.reset()

    -- Reset Balls
    for i=1, #Balls, 1 do
        table.remove(Balls, _)
    end
    Balls.initialize() -- Assuming you have an `initialize` function for Balls

    -- Reset other game states (e.g., bricks, score)
    initializeBricks()

    -- Unfreeze the game
    UtilityFunction.freeze = false
end

function GameOverDraw()
    -- Draw a gray overlay on the screen
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7) -- Gray color with 70% opacity
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Display "Game Over" text
    love.graphics.setColor(1, 1, 1, 1) -- White color for the text
    local font = love.graphics.newFont(48) -- Set a large font size
    love.graphics.setFont(font)
    local text = "Game Over"
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, (love.graphics.getWidth() - textWidth) / 2, (love.graphics.getHeight() - textHeight) / 2)

    -- Draw the restart button
    local buttonWidth, buttonHeight = 150, 50
    local buttonX = (love.graphics.getWidth() - buttonWidth) / 2
    local buttonY = (love.graphics.getHeight() + textHeight) / 2 + 20

    if suit.Button("Restart", {align = "center"}, buttonX, buttonY, buttonWidth, buttonHeight).hit then
        restartGame() -- Call the restart function when the button is clicked
    end

    -- Reset the color to white
    love.graphics.setColor(1, 1, 1, 1)
end

-- Convert HSLA to RGBA
function HslaToRgba(h, s, l, a)
    if s == 0 then
        -- Achromatic (gray)
        return l, l, l, a
    else
        local function hueToRgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1/6 then return p + (q - p) * 6 * t end
            if t < 1/2 then return q end
            if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
            return p
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        local r = hueToRgb(p, q, h/360 + 1/3)
        local g = hueToRgb(p, q, h/360)
        local b = hueToRgb(p, q, h/360 - 1/3)
        return r, g, b, a
    end
end

function normalizeVector(x, y)
    local magnitude = math.sqrt(x^2 + y^2)
    if magnitude == 0 then
        return 0, 0 -- Return a zero vector if the magnitude is 0
    end
    return x / magnitude, y / magnitude
end

function getKeysAsList(list)
    local keys = {}
    for key, _ in pairs(list) do
        table.insert(keys, tostring(key)) -- Add each key as a string
    end
    return keys -- Return the list of keys
end

local Fonts = {}
function setFont(...)
    local args = {...}
    local fontSize = 12 -- Default font size
    local fontType = nil
    if not love.graphics.getFont() == nil then
        fontSize = love.graphics.getFont():getSize() or 12 -- Default font size
        fontType = love.graphics.getFont():getName() -- Default font type
    end
    for _, arg in ipairs(args) do
        if type(arg) == "number" then
            fontSize = arg -- Set the font size to the first number found
        elseif type(arg) == "string" then
            fontType = arg -- Set the font type to the first string found
        else
            error("invalid argument in setFont, expected number or string") 
        end
    end
    local font
    if fontType == nil then
        if Fonts[fontSize] then
            font = Fonts[fontSize] -- Use the cached font if it exists
        else
            font = love.graphics.newFont(fontSize) -- Create a new font if it doesn't exist
            Fonts[fontSize] = font -- Cache the new font
        end
        font = love.graphics.newFont(fontSize)
    else 
        font = love.graphics.newFont(fontType, fontSize)
    end
    love.graphics.setFont(font) -- Set the font in Love2D
end -- Missing 'end' added here

function areBallsInRange(ball1, ball2, range)
    -- Calculate the distance between the centers of the two balls
    local dx = ball1.x - ball2.x
    local dy = ball1.y - ball2.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Check if the distance is less than or equal to the range
    -- We subtract the radii of both balls to make the calculation more accurate
    return distance <= range + ball1.radius + ball2.radius
end

function tableLength(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function getRandomValueFromTable(tbl)
    local values = {}
    for _, value in pairs(tbl) do
        table.insert(values, value)
    end
    return values[math.random(#values)]
end

function drawCenteredText(text, x, y, font, textColor)
    love.graphics.setFont(font) -- Set the font
    love.graphics.setColor(textColor) -- Set the text color

    -- Get the width and height of the text
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()

    -- Calculate the top-left position to center the text
    local drawX = x - textWidth / 2
    local drawY = y - textHeight / 2

    -- Draw the text
    love.graphics.print(text, drawX, drawY)

    -- Reset the color to white
    love.graphics.setColor(1, 1, 1, 1)
end

function drawTextWithOutline(text, x, y, font, textColor, outlineColor, outlineThickness)
    love.graphics.setFont(font)

    -- Set the outline color and draw the text around the main text
    love.graphics.setColor(outlineColor)
    for dx = -outlineThickness, outlineThickness, outlineThickness do
        for dy = -outlineThickness, outlineThickness, outlineThickness do
            if dx ~= 0 or dy ~= 0 then
                drawCenteredText(text, x + dx, y + dy, font, outlineColor)
            end
        end
    end

    -- Draw the main text using drawCenteredText
    drawCenteredText(text, x, y, font, textColor)

    -- Reset the color to white
    love.graphics.setColor(1, 1, 1, 1)
end

function drawFPS()
    local fps = love.timer.getFPS() -- Get the current FPS
    local font = love.graphics.newFont(14) -- Set a small font for the FPS display
    love.graphics.setFont(font)
    love.graphics.setColor(0, 1, 0, 1) -- Green color for the FPS text
    love.graphics.print("FPS: " .. fps, screenWidth - 100, 10) -- Draw FPS at the top-right corner
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
end

function countStringKeys(tbl)
    local count = 0
    for key, _ in pairs(tbl) do
        if type(key) == "string" then
            count = count + 1
        end
    end
    return count
end

local lastId = 0 -- Initialize a variable to keep track of the last ID used
local buttonIDs = {} -- Table to keep track of button IDs
function generateNextButtonID(...)
    lastId = lastId + 1 -- Increment the last ID by 1
    return lastId -- Return the new ID
end

function resetButtonLastID()
    lastId = 0 -- Reset the last ID to 0
end

function getTextSize(text)
    -- Create a temporary font with the specified size
    local font = love.graphics.getFont()
    if not font then
        error("Font not set. Please set a font before calling getTextSize.")
    end
    -- Get the width and height of the text
    local width = font:getWidth(text)
    local height = font:getHeight()
    return width, height
end

function formatNumber(value)
    if value >= 1e12 then
        return string.format("%.3gT", value / 1e12) -- Trillions
    elseif value >= 1e9 then
        return string.format("%.3gB", value / 1e9) -- Billions
    elseif value >= 1e6 then
        return string.format("%.3gM", value / 1e6) -- Millions
    elseif value >= 1e3 then
        return string.format("%.3gK", value / 1e3) -- Thousands
    else
        return tostring(value) -- Less than 1000, no suffix
    end
end

local Tweens = {} -- Table to store tweens
function addTweenToUpdate(tween)
    table.insert(Tweens, tween) -- Add the tween to the list
end
function updateAllTweens(dt)
    for _, tween in ipairs(Tweens) do
        if tween.update then
            tween:update(dt) -- Update each tween
            if tween.clock >= tween.duration then
                tween = nil
            end
        end
    end
end

explosions = {} -- Table to store explosions

function addExplosion(x, y, radius, duration, speed, color)
    local explosion = {
        x = x,
        y = y,
        radius = radius,
        duration = duration,
        speed = speed,
        color = color or {1, 1, 0, 1}, -- Default to yellow if no color is provided
        clock = 0 -- Initialize the clock for the explosion
    }
    table.insert(explosions, explosion) -- Add the explosion to the list
end

-- function to calculate circle hitboxes
function getBricksTouchingCircle(circleX, circleY, radius)
    local bricksTouchingCircle = {}

    for _, brick in ipairs(bricks) do
        if not brick.destroyed then
            -- Calculate the closest point on the brick to the circle's center
            local closestX = math.max(brick.x, math.min(circleX, brick.x + brick.width))
            local closestY = math.max(brick.y, math.min(circleY, brick.y + brick.height))

            -- Calculate the distance between the circle's center and the closest point
            local distanceX = circleX - closestX
            local distanceY = circleY - closestY
            local distanceSquared = distanceX^2 + distanceY^2

            -- Check if the distance is less than or equal to the circle's radius squared
            if distanceSquared <= radius^2 then
                table.insert(bricksTouchingCircle, brick)
            end
        end
    end
    return bricksTouchingCircle
end

function drawExplosions()
    for _, explosion in ipairs(explosions) do
        love.graphics.setColor(explosion.color) -- Set the explosion color
        love.graphics.circle("fill", explosion.x, explosion.y, explosion.radius) -- Draw the explosion
    end
end

function explosionsUpdate(dt)
    for _, explosion in ipairs(explosions) do
        explosion.radius = explosion.radius + explosion.speed * dt -- Update the explosion radius
        if explosion.clock >= explosion.duration then
            table.remove(explosions, _) -- Remove the explosion if its duration is over
        end
    end
end

local animations = {}
function createSpriteAnimation(x, y, scale, spritesheet, frameWidth, frameHeight, frameTime)
    local animation = {}
    animation.x = x
    animation.y = y
    animation.scale = scale
    animation.spritesheet = spritesheet
    animation.frameWidth = frameWidth
    animation.frameHeight = frameHeight
    animation.frameTime = frameTime
    animation.elapsedTime = 0
    animation.currentFrame = 1
    animation.quads = {}

    -- Calculate the number of frames in the spritesheet
    local sheetWidth = spritesheet:getWidth()
    local sheetHeight = spritesheet:getHeight()

    for y = 0, sheetHeight - frameHeight, frameHeight do
        for x = 0, sheetWidth - frameWidth, frameWidth do
            table.insert(animation.quads, love.graphics.newQuad(x, y, frameWidth, frameHeight, sheetWidth, sheetHeight))
        end
    end
    table.insert(animations, animation) -- Store the animation in the animations table
end

-- Update function for the animation
function updateAnimations(dt)
    for _, animation in ipairs(animations) do
        animation.elapsedTime = animation.elapsedTime + dt
        if animation.elapsedTime >= animation.frameTime then
            animation.elapsedTime = animation.elapsedTime - animation.frameTime
            animation.currentFrame = animation.currentFrame + 1
            if animation.currentFrame > #animation.quads then
                table.remove(animations, _) -- Remove the animation if it has finished
                animation = nil
            end
        end
    end
    
end

function drawAnimations()
    for _, animation in ipairs(animations) do
        love.graphics.draw(
            animation.spritesheet,
            animation.quads[animation.currentFrame],
            animation.x,
            animation.y,
            0, -- Rotation (default to 0)
            animation.scale, -- Scale X
            animation.scale, -- Scale Y
            animation.frameWidth / 2, -- Origin X (half the frame width)
            animation.frameHeight / 2 -- Origin Y (half the frame height)
        )
    end
end

return UtilityFunction
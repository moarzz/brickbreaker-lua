-- filepath: c:\Users\xavie\OneDrive\Documents\GitHub\brickbreaker\UtilityFunction.lua
local UtilityFunction = {
    freeze = false -- Global freeze variable to control game state
}

FontReference = {default = "assets/Fonts/borderedPixelated.ttf"}

function toggleFreeze()
    UtilityFunction.freeze = not UtilityFunction.freeze
    print("game is now " .. (UtilityFunction.freeze and "frozen" or "unfrozen"))
end

-- Function to combine two lists
function addLists(list1, list2)
    local result = {}
    for _, value in ipairs(list1) do
        table.insert(result, value)
    end
    for _, value in ipairs(list2) do
        table.insert(result, value)
    end
    return result
end

function restartGame()
    -- Reset Player
    Player.money = 0
    Player.lives = 1
    Player.dead = false
    Player.bonuses = {
        critChance = 0,
        income = 0,
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

SFXs = {}
function playSoundEffect(soundEffect, volume, pitch, loop, clone)
    if soundEffect ~= backgroundMusicSFX then
        volume = (sfxVolume or 1) * (volume or 1) * 0.5 -- Adjust volume based on global sfxVolume
    end
    if Player.dead and currentGameState == GameState.PLAYING then
        return
    end
    pitch = math.max(pitch, 0.1)
    clone = clone or true -- Default to false if not provided
    if clone then
        soundEffect = soundEffect:clone() -- Clone the sound effect if specified
    end
    soundEffect:setVolume(volume or 1) -- Set the volume (default to 1)
    soundEffect:setPitch(pitch or 1) -- Set the pitch (default to 1)
    soundEffect:setLooping(loop or false) -- Set looping (default to false)
    soundEffect:play() -- Play the sound effect
end

function GameOverDraw()
    -- Draw a dark overlay on the screen
    love.graphics.setColor(0, 0, 0, 0.8) -- Dark overlay with 80% opacity
    love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)

    -- Reset color for UI elements
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw "Game Over" text at the top
    setFont(64)
    local text = "Game Over"
    local currentFont = love.graphics.getFont()
    local textWidth = currentFont:getWidth(text)
    local textHeight = currentFont:getHeight()
    love.graphics.print(text, (screenWidth - textWidth) / 2, 100)

    -- Draw Score (top left)
    setFont(50)
    local scoreText = "Score: " .. formatNumber(Player.score) .. " pts"
    love.graphics.setColor(99/255, 170/255, 1, 1)
    love.graphics.print(scoreText, 50, 200)
    local scoreWidth = currentFont:getWidth(scoreText)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white

    -- Draw High Score below Score
    setFont(32)
    local highScoreText = "High Score: " .. formatNumber(Player.highScore) .. " pts"
    love.graphics.setColor(99/255, 170/255, 1, 1)
    love.graphics.print(highScoreText, 50, 270)

    -- Draw the number of bricks destroyed (bottom right corner, above gold earned)
    setFont(40)
    local bricksDestroyedText = "Bricks Destroyed: " .. tostring(Player.bricksDestroyed or 0)
    love.graphics.setColor(1, 0.8, 0.4, 1)
    local bricksTextWidth = love.graphics.getFont():getWidth(bricksDestroyedText)
    local bricksTextX = screenWidth - bricksTextWidth - 50
    local bricksTextY = 270
    love.graphics.print(bricksDestroyedText, bricksTextX, bricksTextY)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setColor(1, 0, 0, 1) -- Set color to red for the "Game Over" text
    setFont(20)
    if newHighScore then
        love.graphics.print("New High Score!", scoreWidth - 100, 150, math.rad(15))
    end
    
    -- Draw gold Earned (top right)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    setFont(48)
    local goldEarned = math.floor(math.sqrt(Player.score) <= 300 and (mapRangeClamped(math.sqrt(Player.score), 0, 300, 1.5, 3) * math.sqrt(Player.score)) or (mapRangeClamped(math.sqrt(Player.score), 300, 600, 3, 5) * math.sqrt(Player.score)))
    local goldText = "gold earned: ".. formatNumber(goldEarned) .. "$"
    currentFont = love.graphics.getFont()
    local moneyWidth = currentFont:getWidth(goldText)
    love.graphics.setColor(231/255, 184/255, 0, 1) -- Set color to gold
    love.graphics.print(goldText, screenWidth - moneyWidth - 50, 200)
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw buttons
    local buttonWidth = 400
    local buttonHeight = 75
    local buttonSpacing = 50
    local totalWidth = (buttonWidth * 3) + (buttonSpacing * 2)
    local startX = (screenWidth - totalWidth) / 2
    local buttonY = screenHeight / 2 + 200

    -- Upgrades button (left)
    if dress:Button("Upgrades", {id = generateNextButtonID()}, startX, buttonY, buttonWidth, buttonHeight).hit then
        currentGameState = GameState.UPGRADES
        Player.reset()
    end

    -- Main Menu button (center)
    if dress:Button("Main Menu", {id = generateNextButtonID()}, startX + buttonWidth + buttonSpacing, buttonY + 75, buttonWidth, buttonHeight).hit then
        currentGameState = GameState.MENU
        Player.reset()
    end    
    
    -- Play Again button (right)
    if dress:Button("Play Again", {id = generateNextButtonID()}, startX + (buttonWidth + buttonSpacing) * 2, buttonY, buttonWidth, buttonHeight).hit then
        resetGame()
        currentGameState = GameState.START_SELECT
    end

    -- Reset the color to white
    love.graphics.setColor(1, 1, 1, 1)
end

-- Convert HSLA to RGBA
function hslaToRgba(h, s, l, a)
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

function randomFloat(min, max)
    return min + (max - min) * math.random()
end

function rotateVector(x, y, angle)
    local cosTheta = math.cos(angle)
    local sinTheta = math.sin(angle)
    local rotatedX = x * cosTheta - y * sinTheta
    local rotatedY = x * sinTheta + y * cosTheta
    return rotatedX, rotatedY
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
            -- default font type
            font = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf",fontSize)
            Fonts[fontSize] = font -- Cache the new font
        end
    else 
        if Fonts[fontType .. tostring(fontSize)] then
            font = Fonts[fontType .. tostring(fontSize)] -- Use the cached font if it exists
        else
            font = love.graphics.newFont(fontType, fontSize)
            Fonts[fontType .. tostring(fontSize)] = font
        end
    end
    love.graphics.setFont(font) -- Set the font in Love2D
end -- Missing 'end' added here








-- fancyTexts lol completely lost
fancyTexts = {}








function drawImageCentered(image, x, y, targetWidth, targetHeight, angle)
    -- Get the original dimensions of the image
    local imageWidth = image:getWidth()
    local imageHeight = image:getHeight()

    -- Calculate scaling factors
    local scaleX = targetWidth / imageWidth
    local scaleY = targetHeight / imageHeight

    -- Calculate the offset to center the rotation pivot
    local offsetX = imageWidth / 2
    local offsetY = imageHeight / 2

    -- Draw the image with center rotation
    -- The offset parameters shift the pivot point to the center of the original image
    love.graphics.draw(image, x, y, angle or 0, scaleX, scaleY, offsetX, offsetY)
end

function areBallsInRange(ball1, ball2, range)
    -- Calculate the distance between the centers of the two balls
    local dx = ball1.x - ball2.x
    local dy = ball1.y - ball2.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Check if the distance is less than or equal to the range
    -- We subtract the radii of both balls to make the calculation more accurate
    return distance <= range + ball1.radius + ball2.radius
end

function isBallInRange(ball, x, y, range)
    -- Calculate the distance between the ball's center and the target point (x, y)
    local dx = ball.x - x
    local dy = ball.y - y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Check if the distance is less than or equal to the range
    return distance <= range + ball.radius
end

function isBrickInRange(brick, x, y, range)
    -- Calculate the closest point on the brick to the circle's center
    local closestX = math.max(brick.x, math.min(x, brick.x + brick.width))
    local closestY = math.max(brick.y, math.min(y, brick.y + brick.height))

    -- Calculate the distance between the circle's center and the closest point
    local distanceX = x - closestX
    local distanceY = y - closestY
    local distanceSquared = distanceX^2 + distanceY^2

    -- Check if the distance is less than or equal to the circle's radius squared
    return distanceSquared <= range^2

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
    -- Convert to number if it's a string
    if type(value) == "string" then
        value = tonumber(value)
    end
    
    -- Return early if not a number
    if type(value) ~= "number" then
        return tostring(value)
    end
    
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

function getMaxFittingFontSize(text, maxFontSize, cellWidth)
    local fontSize = maxFontSize
    setFont(fontSize)
    local textWidth = getTextSize(text)
    while textWidth > cellWidth and fontSize > 1 do
        fontSize = fontSize - 1
        setFont(fontSize)
        textWidth = getTextSize(text)
    end
    return fontSize
end

--Tween functions
Tweens = {} -- Table to store tweens
local currentTweenID = 0 -- Initialize a variable to keep track of the current tween ID
function addTweenToUpdate(tween)
    tween.id = currentTweenID
    currentTweenID = currentTweenID + 1
    table.insert(Tweens, tween) -- Add the tween to the list
    return #Tweens
end

function removeTween(tweenID)
    for _, tween in ipairs(Tweens) do
        if tween.id == tweenID then
            table.remove(Tweens, _) -- Remove the tween from the list
            break
        end
    end
end

function updateAllTweens(dt)
    for i = #Tweens, 1, -1 do -- Iterate backward to safely remove items
        local tween = Tweens[i]
        if tween.update then
            tween:update(dt) -- Update each tween
            if tween.clock >= tween.duration then
                table.remove(Tweens, i) -- Remove the tween if its duration is over
            end
        end
    end
end


function mapRangeClamped(x, in_min, in_max, out_min, out_max)
    if x < in_min then
        return out_min
    elseif x > in_max then
        return out_max
    end
    return (x - in_min) / (in_max - in_min) * (out_max - out_min) + out_min
end

function mapRange(x, in_min, in_max, out_min, out_max)
    return (x - in_min) / (in_max - in_min) * (out_max - out_min) + out_min
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
function getBricksInCircle(circleX, circleY, radius)
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

function boomUpdate(dt)
    for _, explosion in ipairs(explosions) do
        explosion.radius = explosion.radius + explosion.speed * dt -- Update the explosion radius
        if explosion.clock >= explosion.duration then
            table.remove(explosions, _) -- Remove the explosion if its duration is over
        end
    end
end

local animationID = 1
animations = {}

function resetAnimations()
    animations = {} -- Reset the animations table
    animationID = 1 -- Reset the animation ID counter
end

function createSpriteAnimation(x, y, scale, spritesheet, frameWidth, frameHeight, frameTime, skipFrames, looping, scaleX, scaleY, angle, color, isFire, brickId)
    looping = looping or false
    local animation = {}
    animation.id = animationID
    animation.x = x
    animation.y = y
    animation.scale = scale
    animation.scaleX = scaleX or 1 -- Default to 1 if not provided
    animation.scaleY = scaleY or 1 -- Default to 1 if not provided
    animation.spritesheet = spritesheet
    animation.frameWidth = frameWidth
    animation.frameHeight = frameHeight
    animation.frameTime = frameTime
    animation.elapsedTime = 0
    animation.currentFrame = 1 + (skipFrames or 0)
    animation.looping = looping or false
    animation.quads = {}
    animation.angle = angle or 0 -- Default to 0 if not provided
    animation.color = color or {1,1,1,1} -- Default alpha value for the animation
    animation.isFire = isFire or false -- Flag to indicate if this is a fire animation
    animation.brickId = brickId or nil -- Store the brick ID if applicable

    animationID = animationID + 1 -- Increment the animation ID for the next animation

    -- Calculate the number of frames in the spritesheet
    local sheetWidth = spritesheet:getWidth()
    local sheetHeight = spritesheet:getHeight()

    for y = 0, sheetHeight - frameHeight, frameHeight do
        for x = 0, sheetWidth - frameWidth, frameWidth do
            table.insert(animation.quads, love.graphics.newQuad(x, y, frameWidth, frameHeight, sheetWidth, sheetHeight))
        end
    end
    table.insert(animations, animation) -- Store the animation in the animations table
    return animation.id
end

function cooldownVFX(duration, x, y)
    local timer = 0
    local function update(dt)
        timer = timer + dt
        if timer >= duration then
            -- Create a visual effect at (x, y)
            createSpriteAnimation(x, y)
            return true -- Stop the update
        end
        return false -- Continue the update
    end
    return update
end

function getAnimation(id)
    for _, animation in ipairs(animations) do
        if animation.id == id then
            return animation -- Return the animation if found
        end
    end
    return nil -- Return nil if no animation with the given ID is found
end

local lvlUpTexts = {}
local boostTexts = {}
local currentPopupId = 1
function lvlUpPopup()
    playSoundEffect(lvlUpSFX, 0.55, 1, false)
    local popup = {
        id = currentPopupId,
        x = paddle.x + paddle.width/2,
        y = paddle.y + paddle.height/2,
        size = 0,
        color = {0, 0.25, 1, 1}  -- RGB + Alpha
    }
    local textString = Player.level % 2 == 0 and "+Size" or "+Speed"
    local popup2 = {
        id = currentPopupId,
        text = textString,
        x = paddle.x + paddle.width/2,
        y = paddle.y + paddle.height/2,
        size = 0,
        color = {0, 0.25, 1, 1}  -- RGB + Alpha
    }
    currentPopupId = currentPopupId + 1 -- Increment the popup ID for the next popup
    local popupSizeTween = tween.new(0.1, popup, {size = 50}, tween.easing.outExpo)
    addTweenToUpdate(popupSizeTween)
    local popupSizeTween2 = tween.new(0.1, popup2, {size = 30}, tween.easing.outExpo)
    addTweenToUpdate(popupSizeTween2)
    Timer.after(1.1, function() 
        local popupSizeTweenOut = tween.new(0.4, popup, {size = 0}, tween.easing.inExpo)
        addTweenToUpdate(popupSizeTweenOut)
        local popupSizeTweenOut2 = tween.new(0.4, popup2, {size = 0}, tween.easing.inExpo)
        addTweenToUpdate(popupSizeTweenOut2)
    end)
    local xVelocity = math.random(-50, 50) + mapRangeClamped(paddle.x + paddle.width/2, statsWidth, screenWidth - statsWidth, 150, -150)
    local yVelocity = math.random(-275, -150)
    local totalLengthTween = tween.new(1.5, popup, {x = popup.x + xVelocity, y = popup.y + yVelocity}, tween.easing.outExpo)
    addTweenToUpdate(totalLengthTween)
    local totalLengthTween2 = tween.new(1.5, popup2, {x = popup2.x + xVelocity * 1, y = popup2.y + yVelocity*0.6}, tween.easing.outExpo)
    addTweenToUpdate(totalLengthTween2)
    table.insert(lvlUpTexts, popup)
    table.insert(boostTexts, popup2)
    Timer.after(1.5, function()
        -- Remove the popup after the total length tween is complete
        for i = #lvlUpTexts, 1, -1 do
            if lvlUpTexts[i].id == popup.id then
                table.remove(lvlUpTexts, i)
                break
            end
        end
        for i = #boostTexts, 1, -1 do
            if boostTexts[i].id == popup2.id then
                table.remove(boostTexts, i)
                break
            end
        end
    end)
end

function resetLvlUpPopups()
    lvlUpTexts = {}
    boostTexts = {}
    currentPopupId = 1
end

function drawLvlUpPopups()
    for i = #lvlUpTexts, 1, -1 do
        local popup = lvlUpTexts[i]
        if not popup then
            table.remove(lvlUpTexts, i)
            goto continue
        end
        if popup.size > 0 then  -- Only draw if size is positive
            setFont(math.max(1, math.ceil(popup.size)))
            love.graphics.setColor(popup.color[1], popup.color[2], popup.color[3], popup.color[4] or 1)
            setFont(math.max(1, math.floor(popup.size)))  -- Ensure font size is at least 1 and is an integer
            love.graphics.print("Level Up!", popup.x - getTextSize("Level Up!")/2, popup.y)  -- Center the text
        end
        ::continue::
    end
    for i = #boostTexts, 1, -1 do
        local popup = boostTexts[i]
        if not popup then
            table.remove(boostTexts, i)
            goto continue
        end
        if popup.size > 0 then  -- Only draw if size is positive
            setFont(math.max(1, math.ceil(popup.size)))
            love.graphics.setColor(1,1,1,1)
            setFont(math.max(1, math.floor(popup.size)))  -- Ensure font size is at least 1 and is an integer
            love.graphics.print(popup.text, popup.x - getTextSize("Boost!")/2, popup.y)  -- Center the text
        end
        ::continue::
    end
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white after drawing popups
end

function removeAnimation(id)
    for i = #animations, 1, -1 do
        if animations[i] == nil then
            table.remove(animations, i)
            goto continue -- Skip to the next iteration
        end
        if animations[i].id == id then
            table.remove(animations, i)
            --animations[i] = nil
            return true -- Return true to indicate successful removal
        end
        ::continue::
    end
    return false -- Return false if no animation with the given ID is found
end

-- Store animations grouped by spritesheet
local spriteBatches = {}

-- Update function for the animation
function updateAnimations(dt)
    -- Clear sprite batches each frame
    for _, batch in pairs(spriteBatches) do
        batch:clear()
    end

    for i = #animations, 1, -1 do
        local animation = animations[i]
        if not animation then
            table.remove(animations, i) -- Remove nil animations
            goto continue -- Skip to the next iteration
        end
        animation.elapsedTime = animation.elapsedTime + dt
        if animation.elapsedTime >= animation.frameTime then
            animation.elapsedTime = animation.elapsedTime - animation.frameTime
            animation.currentFrame = animation.currentFrame + 1
            if animation.currentFrame > #animation.quads then
                if animation.looping then
                    animation.currentFrame = 1
                else
                    table.remove(animations, i) -- Remove the animation if it has finished
                    goto continue
                end
            end
        end

        -- Add to sprite batch using the spritesheet object as the key
        if not spriteBatches[animation.spritesheet] then
            spriteBatches[animation.spritesheet] = love.graphics.newSpriteBatch(animation.spritesheet, 1000)
        end
        
        -- Add to batch with all the same parameters as before
        spriteBatches[animation.spritesheet]:add(
            animation.quads[animation.currentFrame],
            animation.x,
            animation.y,
            math.rad(animation.angle),
            animation.scale * animation.scaleX,
            animation.scale * animation.scaleY,
            animation.frameWidth / 2,
            animation.frameHeight / 2,
            0, 0, -- shearing
            animation.color[1], animation.color[2], animation.color[3], animation.color[4]
        )
        ::continue::
    end
end

function drawAnimations()
    -- Draw all sprite batches
    love.graphics.setColor(1, 1, 1, 1)
    for _, batch in pairs(spriteBatches) do
        love.graphics.draw(batch)
    end
end

-- Example: Elastic tween that ends with the same value
local function createElasticTween(duration, subject, property, overshoot, easing)
    local startValue = subject[property]
    local targetValue = startValue + overshoot -- Add an overshoot value

    -- Create a tween that animates to the overshoot and back to the start value
    local elasticTween = tween.new(duration, subject, {[property] = targetValue}, easing)

    -- Add a second tween to return to the start value
    local returnTween = tween.new(duration, subject, {[property] = startValue}, easing)

    return {elasticTween, returnTween}
end

currentScreenShakeIntensity = 0 -- Initialize the screen shake intensity
local currentScreenShakeDirection = true
local screenShaking = false
local function singularScreenShake(intensity, rightDirection)
    screenShaking = true
    local shakeTween = nil
    local easing = tween.easing.outSine
    local delay = 0
    local duration = 0.5

    if rightDirection then
        shakeTween = tween.new(duration/(vibrationCount+1), screenOffset, {x = -currentScreenShakeIntensity*direction[1], y = -currentScreenShakeIntensity*direction[2]}, easing)
    else
        shakeTween = tween.new(duration/(vibrationCount+1), screenOffset, {x = currentScreenShakeIntensity*direction[1], y = currentScreenShakeIntensity*direction[2]}, easing)
    end
    addTweenToUpdate(shakeTween)

    Timer.after(delay, function() 
        currentScreenShakeDirection = not currentScreenShakeDirection
        if currentScreenShakeIntensity >= 1 then
            singularScreenShake(currentScreenShakeIntensity, currentScreenShakeDirection)
        else
            screenShaking = false
            currentScreenShakeIntensity = 0
        end
    end)
end

function screenShake(duration, intensity, vibrationCount, direction)
    -- This function has 1 more vibration than vibrationCount
    direction = direction or {1, 0} -- Default direction
    intensity = intensity or 10 -- Default intensity
    intensity = mapRangeClamped(intensity, 1, 100, 1, 50)
    duration = duration or 0.5 -- Default duration
    vibrationCount = vibrationCount or 3 -- Default number of vibrations
    local delay = 0 -- Default duration multiplier

    for i = 0, vibrationCount do
        Timer.after(delay, function()
            local shakeTween = nil
            local currentVibration = i
            local easing = tween.easing.outSine
            currentScreenShakeIntensity = intensity*((vibrationCount-currentVibration)/vibrationCount) 

            if currentVibration%2 == 0 then
                shakeTween = tween.new(duration/(vibrationCount+1), screenOffset, {x = -currentScreenShakeIntensity*direction[1], y = -currentScreenShakeIntensity*direction[2]}, easing)
            else
                shakeTween = tween.new(duration/(vibrationCount+1), screenOffset, {x = currentScreenShakeIntensity*direction[1], y = currentScreenShakeIntensity*direction[2]}, easing)
            end
            addTweenToUpdate(shakeTween)
        end)
        delay = delay + (duration/(vibrationCount + 1))
    end
end

function screenShakeIntensityDeprecation(dt)
    currentScreenShakeIntensity = math.max(currentScreenShakeIntensity - dt * currentScreenShakeIntensity * 2, 0)
end

function screenFlash(duration, intensity)
    -- Create a tween for the flash effect
    local easing = tween.easing.outSine
    local delay = duration / 8
    backgroundIntensity = math.max(intensity, 0.25)

    local flashTween = tween.new(duration, backgroundColor, {r = 0, g = 0, b = 0, a = 0}, tween.easing.inSine)
    addTweenToUpdate(flashTween)
end

local canDamageScreenVisuals = true
function damageScreenVisuals(duration, intensity, direction)
    canDamageScreenVisuals = false -- Prevent further damage until the current effect is done
    Timer.after(0.25, function()
        canDamageScreenVisuals = true -- Allow further damage after the duration
    end)

    --local directionX, directionY = normalizeVector(math.random(-1000, 1000), math.random(-1000, 1000)) -- Random direction for the screen shake
    local directionX, directionY = normalizeVector(5, 3) -- Fixed direction for the screen shake
    direction = direction or {directionX, directionY} -- Use the random direction if not provided
    direction = {directionX, directionY}

    --screen flash logic
    local flashIntensity = mapRangeClamped(intensity, 0, 10, 0, 1)
    local flashColor = {flashIntensity, flashIntensity, flashIntensity, flashIntensity} -- Red color for the flash effect
    if flashIntensity > backgroundIntensity then
        local color = flashColor
        backgroundIntensity = flashIntensity
        --screenFlash(0.25, flashColor)
    end

    --screen shake logic
    --currentScreenShakeIntensity = math.max((intensity/3)^0.5, currentScreenShakeIntensity)
    --singularScreenShake(currentScreenShakeDirection, currentScreenShakeDirection)


    --[[if intensity > currentScreenShakeIntensity then
        screenShake(duration, mapRangeClamped(intensity , 
            mapRangeClamped(intensity,1,10,1,10), 
            100, 
            mapRangeClamped(intensity, mapRangeClamped(intensity,1,5,1,5), 10, mapRangeClamped(intensity,1,5,2,10), 15), 
            50), math.floor(mapRangeClamped(intensity, 1, 100, 3, 6)),
            direction)
    end]]
end

local muzzleFlashes = {}

function muzzleFlash(x, y, angle)
    table.insert(muzzleFlashes, {
        x = x,
        y = y,
        angle = angle or 0,
        frame = love.timer.getTime()
    })
end

function drawMuzzleFlashes()
    for i = #muzzleFlashes, 1, -1 do
        local flash = muzzleFlashes[i]
        -- Only draw if it's the current frame
        if love.timer.getTime() - flash.frame < (1 / love.timer.getFPS() + 0.001) then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(muzzleFlashImg, flash.x, flash.y - muzzleFlashImg:getHeight()/4, flash.angle, 0.25, 0.25, muzzleFlashImg:getWidth()/2, muzzleFlashImg:getHeight()/2)
        else
            table.remove(muzzleFlashes, i)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

-- Store damage numbers and batching resources
local damageNumbers = {} -- Table to store damage numbers
local damageNumberFont = nil -- Cache the font
local textObjects = {} -- Cache Text objects by damage value

function resetDamageNumbers()
    damageNumbers = {} -- Reset the damage numbers table
    -- Clear text object cache
    for _, text in pairs(textObjects) do
        text:release()
    end
    textObjects = {}
end

local damageNumberId = 1
function damageNumber(damage, x, y, color)
    if damage == 0 then return end
    if damage < 0 then 
        healNumber(math.abs(damage),x,y) 
        return
    end
    if damageNumbersOn then
        local damageNumber = {
            x = x,
            y = y,
            damage = damage,
            color = color or {1, 0, 0, 1}, -- Default to red if no color is provided
            alpha = 1,
            fontSize = 0,
            id = damageNumberId
        }
        damageNumberId = damageNumberId + 1
        table.insert(damageNumbers, damageNumber)

        local sizeTween = tween.new(0.75, damageNumber, {fontSize = damage < 10 and mapRange(damage, 0, 10, 1, 3) or mapRangeClamped(damage, 10, 50, 3, 5)}, tween.easing.outBack)
        addTweenToUpdate(sizeTween)

        local xRandom, yRandom = math.random(-15, 15), -15 - math.random(20)
        local offsetTween = tween.new(0.75, damageNumber, {x = x + xRandom, y = y + yRandom}, tween.easing.outQuad)
        addTweenToUpdate(offsetTween)
        Timer.after(0.40, function()
            local alphaTween = tween.new(0.35, damageNumber, {alpha = 0}, tween.easing.outCirc)
            addTweenToUpdate(alphaTween)
        end)
        Timer.after(0.75, function()
            for i = #damageNumbers, 1, -1 do
                if damageNumbers[i].id == damageNumber.id then
                    table.remove(damageNumbers, i) -- Remove the damage number after its duration
                    break
                end
            end
        end)
    end
end

function getRandomFromKey(tbl)
  local len = 0;
  
  -- loop over to find the amount of unique items in the table
  -- (this gets both the keys and the indexed items
  -- for only getting keys check the type of 'k' to not be a number in both for loops before doing anything)
  for _, v in pairs(tbl) do
    len = len + 1;
  end

  local randIndex = love.math.random(len); -- [1-len]

  local ind = 0;

  -- loop through the table again to find the item located at the random point
  for k, v in pairs(tbl) do
    ind = ind + 1;
    
    if ind == randIndex then
      return k, v;
    end
  end

  -- shouldnt be possible to get here
  error("milo is an idiot that cant write a random function apparently");
end

function healNumber(number, x, y)
    if healNumbersOn then
        local healNumber = {
            x = x,
            y = y,
            damage = number,
            color = {125/255, 1, 0, 1},
            alpha = 1,
            fontSize = 0,
            id = damageNumberId
        }
        damageNumberId = damageNumberId + 1
        table.insert(damageNumbers, healNumber)

        local sizeTween = tween.new(0.75, healNumber, {fontSize = number < 10 and mapRange(number, 0, 10, 1, 3) or mapRangeClamped(number, 10, 50, 3, 5)}, tween.easing.outBack)
        addTweenToUpdate(sizeTween)

        local xRandom, yRandom = math.random(-15, 15), -15 - math.random(20)
        local offsetTween = tween.new(0.75, healNumber, {x = x + xRandom, y = y + yRandom}, tween.easing.outQuad)
        addTweenToUpdate(offsetTween)
        Timer.after(0.40, function()
            local alphaTween = tween.new(0.35, healNumber, {alpha = 0}, tween.easing.outCirc)
            addTweenToUpdate(alphaTween)
        end)
        Timer.after(0.75, function()
            for i = #damageNumbers, 1, -1 do
                if damageNumbers[i].id == healNumber.id then
                    table.remove(damageNumbers, i) -- Remove the heal number after its duration
                    break
                end
            end
        end)
    end
end

function drawTextCenteredWithScale(text, x, y, scale, maxWidth, color)
    color = color or {1, 1, 1, 1}
    love.graphics.setColor(color)
    local font = love.graphics.getFont(); -- the font being used
    local drawY = y; -- the y position of th text being draw currently
    local toPrint = text; -- text remaining to print

    while toPrint ~= "" do -- keep looping until 'toPrint' is an empty string
        if font:getWidth(toPrint) * scale > maxWidth then
            local lastWorkingStr = "";

            for str in string.gmatch(toPrint, "[^%s]*%s") do
                if font:getWidth(lastWorkingStr .. str) * scale < maxWidth then
                    lastWorkingStr = lastWorkingStr .. str;
                else
                    break; -- exit the for loop (no use in moving forward since the width can only increase more)
                end
            end

            -- make sure string isnt empty, if it is then fill it with the most letters possible
            if lastWorkingStr == "" then
                for char in string.gmatch(toPrint, ".") do
                    if font:getWidth(lastWorkingStr .. char) * scale < maxWidth then
                        lastWorkingStr = lastWorkingStr .. char;
                    else
                        break;
                    end
                end
            end

            -- clean up the rendered text a bit before drawing it
            local cleanedStr = lastWorkingStr;

            if string.match(cleanedStr, "%s$") then -- if the text ends in a space then exclude it from the draw
                cleanedStr = string.sub(cleanedStr, 1, -2);
            end

            local drawX = x - font:getWidth(cleanedStr) * scale / 2 + maxWidth / 2;
            love.graphics.print(cleanedStr, drawX, drawY, 0, scale, scale);

            toPrint = string.sub(toPrint, string.len(lastWorkingStr) + 1, -1);

            drawY = drawY + font:getHeight("|") * scale;
        else
            local drawX = x - font:getWidth(toPrint) * scale / 2 + maxWidth / 2;

            love.graphics.print(toPrint, drawX, drawY, 0, scale, scale);
            toPrint = "";
        end
    end
end

function drawDamageNumbers()
    -- Initialize font if not cached
    if not damageNumberFont then
        damageNumberFont = love.graphics.newFont("assets/Fonts/KenneyBlocks.ttf", 60)
    end
    love.graphics.setFont(damageNumberFont)

    -- Group numbers by fontSize (rounded to 0.1) to minimize state changes
    local fontGroups = {}
    for _, number in ipairs(damageNumbers) do
        local fontSize = math.floor(number.fontSize * 10) / 10
        fontGroups[fontSize] = fontGroups[fontSize] or {}
        table.insert(fontGroups[fontSize], number)
    end

    -- Draw numbers grouped by font size
    for fontSize, group in pairs(fontGroups) do
        if #group > 0 then
            love.graphics.push()
            love.graphics.scale(fontSize/3, fontSize/3)

            -- Further group by damage value within each font size group
            local valueGroups = {}
            for _, number in ipairs(group) do
                local damage = tostring(number.damage)
                valueGroups[damage] = valueGroups[damage] or {}
                table.insert(valueGroups[damage], number)
            end

            -- Draw each damage value group
            for damage, numbers in pairs(valueGroups) do
                -- Create or get cached Text object
                if not textObjects[damage] then
                    textObjects[damage] = love.graphics.newText(damageNumberFont, damage)
                end
                local text = textObjects[damage]
                local textWidth = text:getWidth()
                local textHeight = text:getHeight()

                -- Draw all instances of this damage value
                for _, number in ipairs(numbers) do
                    love.graphics.setColor(number.color[1], number.color[2], number.color[3], number.color[4] * number.alpha)
                    local x = (number.x * 3 / fontSize) - textWidth/2
                    local y = (number.y * 3 / fontSize) - textHeight/2
                    love.graphics.draw(text, x, y)
                end
            end
            
            love.graphics.pop()
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function printMoney(text, centerX, centerY, angle, buyable, fontSize)
    if buyable == nil then
        buyable = true
    end
    angle = angle or math.rad(1.5) -- Default angle if not provided
    local fontSize = fontSize or 35
    setFont(fontSize)
    local moneyOffsetX = -math.cos(math.rad(5)) * getTextSize(formatNumber(text))/2
    
    -- Draw shadow text

    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(formatNumber(text) .. "$", centerX + 4 + moneyOffsetX, centerY + 4, angle)
    
    -- Draw main text in money green
    local moneyColor = buyable and {14/255, 202/255, 92/255, 1} or {164/255, 14/255, 14/255,1} -- Green for buyable, red for not buyable
    love.graphics.setColor(moneyColor)
    love.graphics.print(formatNumber(text) .. "$", centerX + moneyOffsetX, centerY, angle)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function lerpColor(color1, color2, t)
    return {
        lerp(color1[1], color2[1], t),
        lerp(color1[2], color2[2], t),
        lerp(color1[3], color2[3], t),
        lerp(color1[4] or 1, color2[4] or 1, t)
    }
end

function getBricksInRectangle(x, y, width, height)
    local bricksInRect = {}
    for _, brick in ipairs(bricks) do
        if not brick.destroyed then
            -- Check for rectangle overlap
            if brick.x < x + width and brick.x + brick.width > x and
               brick.y < y + height and brick.y + brick.height > y then
                table.insert(bricksInRect, brick)
            end
        end
    end
    return bricksInRect
end

return UtilityFunction
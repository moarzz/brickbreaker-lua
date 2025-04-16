-- filepath: c:\Users\xavie\OneDrive\Documents\GitHub\brickbreaker\UtilityFunction.lua
local UtilityFunction = {
    freeze = false -- Global freeze variable to control game state
}

function toggleFreeze()
    UtilityFunction.freeze = not UtilityFunction.freeze
    print("game is now " .. (UtilityFunction.freeze and "frozen" or "unfrozen"))
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
    print("Bricks touching circle: " .. #bricksTouchingCircle)
    return bricksTouchingCircle
end

return UtilityFunction
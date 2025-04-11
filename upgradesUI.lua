local suit = require("Libraries.Suit") -- UI library
local upgradesUI = {}

local upgradeOptions = {
    {
        name = "+Paddle speed", 
        description = "Increase Paddle speed by 25%", 
        effect = function() paddle.speed = paddle.speed * 1.25 end
    },
    {
        name = "+Paddle size", 
        description = "Increase Paddle size by 25%", 
        effect = function() paddle.width = paddle.width * 1.25 end
    },
    {
        name = "+Ball", 
        description = "Gain an additional ball", 
        effect = function() Balls.addBall() end
    },
    {
        name = "+Ball damage",
        description = "Increase ball damage by 1",
        effect = function() for _, ball in ipairs(Balls) do Balls.damageIncrease(1, ball) end end
    },
    {
        name = "+XP gain",
        description = "Increase XP gain by 15%",
        effect = function() Player.xpRequiredMult = Player.xpRequiredMult * 0.85 end
    },
    {
        name = "+Money gain",
        description = "Increase money gain by 25%",
        effect = function() Player.money = Player.money * 1.25 end
    },
    {
        name = "+Life",
        description = "Gain an additional life",
        effect = function() Player.lives = Player.lives + 1 end
    },
}

local function drawPlayerStats()
    -- Draw the "Stats" title header
    local statsFont = love.graphics.newFont(20) -- Custom font for stats
    local statsTitleFont = love.graphics.newFont(28) -- Larger font for the title
    love.graphics.setFont(statsTitleFont)
    love.graphics.setColor(1, 0.8, 0, 1) -- Gold color for the title
    love.graphics.printf("Stats", 0, 30, statsWidth, "center") -- Centered title

    -- Draw the stats details
    love.graphics.setFont(statsFont)
    love.graphics.setColor(1, 1, 1, 1) -- White text
    love.graphics.printf("Score: " .. (Player.money or 0), 20, 70, statsWidth - 40, "left")
    love.graphics.printf("Level: " .. (Player.level or 1), 20, 110, statsWidth - 40, "left")
    love.graphics.printf("Lives: " .. (Player.lives or 3), 20, 150, statsWidth - 40, "left")

    -- Add a separator line for better visual clarity
    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray
    love.graphics.rectangle("fill", 10, 200, statsWidth - 20, 2) -- Horizontal line
end

local function drawBallStats()
    local x, y = 20, 200 -- Starting position for the table
    local rowHeight = 30 -- Height of each row
    local columnWidth = 150 -- Width of each column

    -- Initialize the layout with the starting position and padding
    suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)
    --suit.layout:push(suit:getOptionsAndSize()) -- Push the layout stack to start a new layout
    
    local x = {min_height = 300,
    {100, 50},
    {nil, 'fill'},
    {nil, 50},}
    -- Table headers
    suit.Label("Name", {align = "left"}, suit.layout:row(columnWidth, rowHeight))
    suit.Label("Spd", {align = "center"}, suit.layout:col(columnWidth))
    suit.Label("Dmg", {align = "center"}, suit.layout:col(columnWidth))

    -- Iterate through all balls and display their stats
    --suit.layout:pop()
    --suit.layout:nextRow() -- Move to the next row

    for _, ball in ipairs(Balls) do
        suit.layout:row(columnWidth, rowHeight) -- Define the size of each row
        suit.Label(ball.name or "Unknown", {align = "left"}, suit.layout:row())
        suit.Label(tostring(ball.stats.speed or 0), {align = "center"}, suit.layout:col())
        suit.Label(tostring(ball.stats.baseDamage or 0), {align = "center"}, suit.layout:col())

        -- Draw upgrade buttons for each stat
        local buttonResult = suit.Button("+speed", x + columnWidth * 3, y, columnWidth, rowHeight)
        if buttonResult.hit then
            ball.stats.speed = ball.stats.speed + 50 -- Example action
            Balls.adjustSpeed(ball.name) -- Adjust the speed of the ball
        end
    end
end

local displayedUpgrades = {}
function upgradesUI.chooseUpgrades()
    for k in pairs(displayedUpgrades) do
        displayedUpgrades[k] = nil
    end
    for i = 1, 3 do
        local UpgradeID = math.random(1, #upgradeOptions)
        table.insert(displayedUpgrades, upgradeOptions[UpgradeID])
    end
end

local titleFont = love.graphics.newFont(24) -- Create a font with size 24
local descriptionFont = love.graphics.newFont(12) -- Create a font with size 12
local function drawLevelUpShop()
    love.graphics.setColor(0, 0, 0, 1) -- Black color for the background
    love.graphics.rectangle("fill", 150, 100, love.graphics.getWidth()- 300 , love.graphics.getHeight() - 200)
    love.graphics.setColor(1, 1, 1) -- White color for the text
    love.graphics.print("Level Up! Choose an upgrade:", 50, 50)
    -- Add buttons or options for upgrades here
    for i = 1, 3 do 
        local UpgradeID = math.random(1, #upgradeOptions)
        local buttonX = 175 + (i-1) * ((love.graphics.getWidth()- 300)/3)
        local buttonWidth = (love.graphics.getWidth()- 300)/3 - 60
        local buttonHeight = love.graphics.getHeight() - 250
        local mouseX, mouseY = love.mouse.getPosition()
        -- checks if button is hoverd and change color based on if it is
        local isHovered = mouseX >= buttonX and mouseX <= buttonX + buttonWidth and mouseY >= 125 and mouseY <= 125 + buttonHeight
        local color = isHovered and {0.7, 0.7, 0.7, 1} or {0.5, 0.5, 0.5, 1} -- Change color based on hover state
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", 175 + (i-1) * ((love.graphics.getWidth()- 300)/3), 125, (love.graphics.getWidth()- 300)/3 -60, love.graphics.getHeight() - 250) -- Example button
        local name = displayedUpgrades[i].name -- Apply the effect of the upgrade
        love.graphics.setColor(1, 1, 1) -- White color for the text
        love.graphics.setFont(titleFont) -- Set the custom font
        love.graphics.printf(displayedUpgrades[i].name, 175 + (i-1) * ((love.graphics.getWidth()- 300)/3), 150, (love.graphics.getWidth()- 300)/3 -60, "center")
        love.graphics.setFont(descriptionFont) -- Set the font to the description font
        love.graphics.printf(displayedUpgrades[i].description, 175 + (i-1) * ((love.graphics.getWidth()- 300)/3), 200, (love.graphics.getWidth()- 300)/3 -60, "center")
    end
end

function upgradesUI.draw()
    drawPlayerStats() -- Draw the player stats table
    drawBallStats() -- Draw the ball stats table
    if Player.levelingUp then
        drawLevelUpShop()
    end
end

local function detectUpgradeClick(x, y)
    local buttonWidth = (love.graphics.getWidth() - 300) / 3 - 60
    local buttonHeight = love.graphics.getHeight() - 250
    local buttonY = 125

    for i = 1, 3 do
        local buttonX = 175 + (i - 1) * ((love.graphics.getWidth() - 300) / 3)
        if x >= buttonX and x <= buttonX + buttonWidth and y >= buttonY and y <= buttonY + buttonHeight then
            displayedUpgrades[i].effect() -- Apply the effect of the upgrade
            table.remove(displayedUpgrades, i) -- Remove the selected upgrade from the list
            Player.levelingUp = false -- Close the level up shop
            break
        end
    end
end
--Checks if the mouse is over an upgrade button when clicked
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 and Player.levelingUp then -- Left mouse button
        detectUpgradeClick(x, y)
        print("poopy")
    end
end

return upgradesUI
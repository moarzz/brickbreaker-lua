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

local shortStatNames = {
    speed = "Spd",
    damage = "Dmg",
    cooldown = "Cd",
    size = "Size",
    ammount = "Amnt",
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
    love.graphics.printf("Level: " .. (Player.level or 1), 20, 70, statsWidth - 40, "left")
    love.graphics.printf("Lives: " .. (Player.lives or 3), 20, 110, statsWidth - 40, "left")
    love.graphics.printf("Money: " .. (Player.money or 0), 20, 150, statsWidth - 40, "left")

    -- Add a separator line for better visual clarity
    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray
    love.graphics.rectangle("fill", 10, 200, statsWidth - 20, 2) -- Horizontal line
end

local function drawBallStats()  
    local x, y = 20, 230 -- Starting position for the table
    local w, h
    -- Initialize the layout with the starting position and padding
    suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)
    -- Iterate through all balls and display their stats
    for _, ballType in ipairs(Balls.getUnlockedBallTypes()) do
        suit.layout:reset(x, y, 10, 10)
        if #Balls.getUnlockedBallTypes() > 1 then
        end
        local myLayout = {
            min_width = 410, -- Minimum width for the layout
            pos = {x, y}, -- Starting position (x, y)
            padding = {5, 5}, -- Padding between cells
            {80, 30} -- for name
        }
        for x = 1, countStringKeys(ballType.stats) + 1 do -- adds a {"fill"} for each stat in the ballType.stats table
            table.insert(myLayout, {"fill"}) -- for stats
        end
        local definition = suit.layout:cols(myLayout)
        x, y, w, h = definition.cell(1)
        suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)
        setFont(24)
        suit.Label("Name", {align = "left"}, suit.layout:row(w, h)) -- Display the stat name
        setFont(18)
        suit.Label(ballType.name or "Unk", {align = "left"}, suit.layout:row(w, h)) -- Display the ball name
        -- Draw upgrade buttons for each stat
        local intIndex = 2 -- keeps track of the current cell int id being checked
        -- Define the order of keys
        local statOrder = { "ammount", "damage", "speed", "cooldown", "size" }

        -- Create the typeStats table
        local typeStats = { ammount = ballType.ammount } -- Start with ammount
        for statName, statValue in pairs(ballType.stats) do
            typeStats[statName] = statValue -- Add stats to the table
        end

        for _, statName in ipairs(statOrder) do
            local statValue = typeStats[statName] -- Get the value for the current stat
            if statValue then -- Only process if the stat exists
                local buttonResult = nil
                x, y, w, h = definition.cell(intIndex)
                suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)
                setFont(24)
                suit.Label(shortStatNames[statName] or "Unk", {align = "center"}, suit.layout:row(w, h)) -- Display the stat name
                setFont(18)
                suit.layout:padding(0, 0)
                local textWidth = getTextSize(tostring(statValue or 0))
                suit.Label(tostring(statValue or 0), {align = "center"}, suit.layout:row(w, h)) -- Display the stat value
                local buttonID
                buttonID = generateNextButtonID() -- Generate a unique ID for the button
                -- Display the button for upgrading the stat and its cost
                suit.layout:row(w*1.5/4, w) -- makes sure the button is centered even though it is smaller
                print(" w = " .. w/4)
                if statName == "cooldown" and statValue <= 0 then
                    --Cooldown value is maxed out, so we don't show the button
                else 
                    if suit.Button(statName == "cooldown" and "-" or "+" , {id = buttonID, align = "center"}, suit.layout:col(23.75, 23.75)).hit then
                        if Player.money < ballType.price then
                            print("Not enough money to upgrade " .. ballType.name .. "'s " .. statName)
                        else
                            if statName == "speed" then
                                ballType.stats.speed = ballType.stats.speed + 50 -- Example action
                                Balls.adjustSpeed(ballType.name) -- Adjust the speed of the ball
                            elseif statName == "ammount" then
                                Balls.addBall(ballType.name) -- Add a new ball of the same type
                            elseif statName == "cooldown" then
                                ballType.stats.cooldown = ballType.stats.cooldown - 1 -- Example action
                                print( "stat ".. statName .. " decreased to " .. ballType.stats[statName])
                            else
                                ballType.stats[statName] = ballType.stats[statName] + 1 -- Example action
                                print( "stat ".. statName .. " increased to " .. ballType.stats[statName])
                            end
                            Player.money = Player.money - ballType.price -- Deduct the cost from the player's money
                            ballType.price = ballType.price * 2 -- Increase the price of the ball
                        end
                    end
                    setFont(14)
                    suit.Label(formatNumber(ballType.price) .. " $", {align = "left"}, suit.layout:col(65, w/4)) -- Display the cost of the upgrade
                    intIndex = intIndex + 1 -- Increment the index for the next stat
                end
            end
        end
        x, y = suit.layout:nextRow()
        y = y + 20 -- Add padding to the y position for the next row
        x = 20
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
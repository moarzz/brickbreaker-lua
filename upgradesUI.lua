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
    range = "Rng",
}

local buttonWidth, buttonHeight = 35, 25 -- Dimensions for each button

local drawPlayerStatsHeight = 200 -- Height of the player stats section
local function drawPlayerStats()
    -- Initialize the layout for the stats section
    local x, y = 10, 10
    local padding = 10 

    -- Draw the "Stats" title header
    suit.layout:reset(x, y, padding, padding) -- Reset layout with padding
    setFont(28) -- Set font for the title
    suit.Label("Stats", {align = "center"}, suit.layout:row(statsWidth, 40)) -- Title row

    local x, y = suit.layout:nextRow() -- Get the next row position

    local statsLayout = {
        min_width = 450, -- Minimum width for the layout
        pos = {x, y}, -- Starting position (x, y)
        padding = {padding, padding}, -- Padding between cells
        {"fill", 30},
        {"fill"},
        {"fill"}
    }

    local definition = suit.layout:cols(statsLayout) -- Create a column layout for the stats

    -- Draw the stats details
    setFont(20) -- Set font for the stats
    suit.Label("Level: " .. (Player.level or 1), {align = "center"}, definition.cell(1)) -- Level
    suit.Label("Lives: " .. (Player.lives or 3), {align = "center"}, definition.cell(2))
    suit.Label("Money: " .. formatNumber(Player.money), {align = "center"}, definition.cell(3))

    -- Add a separator line for better visual clarity
    suit.layout:row(statsWidth, 30) -- Add spacing for the separator
    local x,y = suit.layout:nextRow()

    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray
    love.graphics.rectangle("fill", 0, y, statsWidth, 2) -- Horizontal line
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
end

local function drawPlayerUpgrades()
    local padding = 10 -- Padding between elements
    local cellWidth, cellHeight = 150, 50 -- Dimensions for each cell
    local rowCount = 3 -- Number of rows

    --drawTitle
    setFont(28) -- Set font for the title
    suit.Label("Player Upgrades", {align = "center", valign = "center"}, suit.layout:row(statsWidth, 60)) -- Title row
    
    -- Define the order of keys for Player.bonuses
    local bonusOrder = { "critChance", "moneyIncome", "ballSpeed", "paddleSpeed", "paddleSize" }
    local rowCount = math.ceil(#bonusOrder/3)

    local intIndex = 1

    for i=1, rowCount, 1 do -- for each row
        local x, y = suit.layout:nextRow()

        local bonusLayout = {
            min_width = 450, -- Minimum width for the layout
            pos = {x, y}, -- Starting position (x, y)
            padding = {padding, padding}, -- Padding between cells
        }

        local colsOnThisRow = math.min(3, #bonusOrder-intIndex+1)
        for i=1, colsOnThisRow, 1 do
            table.insert(bonusLayout, {"fill", 30})
        end
        local definition = suit.layout:cols(bonusLayout) -- Create a column layout for the bonuses

        for i=1, colsOnThisRow, 1 do
            local bonusName = bonusOrder[intIndex] -- Get the bonus name
            local x,y,w,h = definition.cell(i)
            suit.layout:reset(x, y, padding, padding) -- Reset layout with padding

            setFont(18) -- Set font for the stats
            suit.Label(bonusOrder[intIndex], {align = "center"}, suit.layout:row(w, h)) -- Display the stat name
            setFont(16) -- Set font for the stats
            suit.layout:padding(0, 0) -- Reset padding
            suit.Label(tostring(Player.bonuses[bonusName] or 0) .. "%", {align = "center"}, suit.layout:row(w, h)) -- Display the stat value
            local buttonID = generateNextButtonID() -- Generate a unique ID for the button
            suit.layout:padding(0, 0) -- Reset padding
            suit.layout:row((w-30)/2, w) -- makes sure the button is centered even though it is smaller
            if suit.Button("+", {id = buttonID, align = "center"}, suit.layout:col(buttonWidth, buttonHeight)).hit then -- Display the button for upgrading the stat
                -- Check if the player has enough money to upgrade
                if Player.money < Player.price then
                    print("Not enough money to upgrade " .. bonusName)
                else
                    -- Apply the upgrade
                    Player.bonusUpgrades[bonusName]() -- Call the upgrade function
                    Player.Pay(Player.price) -- Deduct the cost from the player's money
                    Player.price = Player.price * 2 -- Double the price for the next upgrade
                    print(bonusName .. " upgraded to " .. Player.bonuses[bonusName] .. "%")
                end
            end
            intIndex = intIndex + 1
        end

        local x,y = suit.layout:nextRow() -- Move to the next row
        suit.layout:reset(0, y, 0, 0)
        suit.layout:row(statsWidth, 15) -- Add spacing for the separator
    end
    
    local x,y = suit.layout:nextRow()
    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray
    love.graphics.rectangle("fill", 0, y, statsWidth, 2) -- Horizontal line
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
end

local function drawBallStats()  
    local x, y = suit.layout:nextRow() -- Get the next row position
    --local x, y = 20, drawPlayerStatsHeight + 30 -- Starting position for the table
    local w, h
    -- Initialize the layout with the starting position and padding
    suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)

    --draw Title
    setFont(28) -- Set font for the title
    suit.Label("Ball Types", {align = "center"}, suit.layout:row(statsWidth, 60))
    local x,y = suit.layout:nextRow()

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
        setFont(20)
        suit.Label("Name", {align = "left"}, suit.layout:row(w, h)) -- Display the stat name
        setFont(16)
        suit.Label(ballType.name or "Unk", {align = "left"}, suit.layout:row(w, h)) -- Display the ball name
        -- Draw upgrade buttons for each stat
        local intIndex = 2 -- keeps track of the current cell int id being checked
        -- Define the order of keys
        local statOrder = { "ammount", "damage", "speed", "cooldown", "range" }

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
                setFont(20)
                suit.Label(shortStatNames[statName] or "Unk", {align = "center"}, suit.layout:row(w, h)) -- Display the stat name
                setFont(16)
                suit.layout:padding(0, 0)
                local textWidth = getTextSize(tostring(statValue or 0))
                suit.Label(tostring(statValue or 0), {align = "center"}, suit.layout:row(w, h)) -- Display the stat value
                local buttonID
                buttonID = generateNextButtonID() -- Generate a unique ID for the button
                -- Display the button for upgrading the stat and its cost
                suit.layout:row(w*1.25/4, w) -- makes sure the button is centered even though it is smaller
                if statName == "cooldown" and statValue <= 0 then
                    --Cooldown value is maxed out, so we don't show the button
                else 
                    setFont(14)
                    if suit.Button(statName == "cooldown" and "-1" or statName == "speed" and "+50" or "+1" , {id = buttonID, align = "center"}, suit.layout:col(buttonWidth, buttonHeight)).hit then
                        if Player.money < ballType.price then
                            print("Not enough money to upgrade " .. ballType.name .. "'s " .. statName)
                        else
                            setFont(16)
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
                            Player.pay(ballType.price) -- Deduct the cost from the player's money
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
    drawPlayerUpgrades() -- Draw the player upgrades table
    drawBallStats() -- Draw the ball stats table
    if Player.levelingUp then
        drawLevelUpShop()
    end

    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray
    love.graphics.rectangle("fill", statsWidth, 0, 2, screenHeight) -- separator line
    love.graphics.rectangle("fill", screenWidth - statsWidth, 0, 2, screenHeight)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
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
    end
end

return upgradesUI
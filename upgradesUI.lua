local suit = require("Libraries.Suit") -- UI library
local upgradesUI = {}

currentlyHoveredButton = nil
local shortStatNames = {
    speed = "Speed",
    damage = "Dmg",
    cooldown = "Cd",
    size = "Size",
    amount = "Amnt",
    range = "Range",
    fireRate = "F.Rate",
    ammo = "Ammo",
}

local buttonWidth, buttonHeight = 25, 25 -- Dimensions for each button

local upgradesQueue = {}
function upgradesUI.queueUpgrade()
    table.insert{upgradesQueue, currentlyHoveredButton}
end
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
    suit.Label("Lives: " .. (Player.lives or 3), {align = "center"}, definition.cell(1))
    suit.Label("Score: " .. formatNumber(Player.score), {align = "center"}, definition.cell(2))
    suit.Label("Money: " .. formatNumber(Player.money), {align = "center"}, definition.cell(3))

    -- Add a separator line for better visual clarity
    suit.layout:row(statsWidth, 40) -- Add spacing for the separator
    local x,y = suit.layout:nextRow()

    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray
    love.graphics.rectangle("fill", 0, y, statsWidth, 2) -- Horizontal line
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
end

local levelUpShopType = "ball"
local displayedUpgrades = {} -- This should be an array, not a table with string keys
local function setLevelUpShop(isForBall)
    displayedUpgrades = {} -- Clear the displayed upgrades
    if isForBall then
        levelUpShopType = "ball"
        -- Ball unlocks
        local unlockedBallNames = {}
        for _, ball in ipairs(Balls.getUnlockedBallTypes()) do
            unlockedBallNames[ball.name] = true
        end
        
        local availableBalls = {}
        for name, ballType in pairs(Balls.getBallList()) do
            if not unlockedBallNames[name] then
                table.insert(availableBalls, ballType)
            end
        end
        
        -- Choose random unowned balls to display
        for i = 1, math.min(3, #availableBalls) do
            if #availableBalls > 0 then
                local index = math.random(1, #availableBalls)
                local currentBallType = availableBalls[index]
                
                table.insert(displayedUpgrades, {
                    name = currentBallType.name,
                    description = currentBallType.description,
                    effect = function()
                        Balls.addBall(currentBallType.name) -- Add the new ball type to the game
                    end
                })
                
                -- Remove this ball from available options
                table.remove(availableBalls, index)
            end
        end
    else
        -- Player upgrades
        levelUpShopType = "playerUpgrade"
        local availableBonuses = {}
        for name, bonus in pairs(Player.bonusesList) do
            if not Player.bonuses[name] then
                table.insert(availableBonuses, bonus)
            end
        end
        
        -- Choose random unowned upgrades
        for i = 1, math.min(3, #availableBonuses) do
            if #availableBonuses > 0 then
                local index = math.random(1, #availableBonuses)
                local currentBonus = availableBonuses[index]
                
                table.insert(displayedUpgrades, {
                    name = currentBonus.name,
                    description = currentBonus.description,
                    effect = function()
                        Player.addBonus(currentBonus.name) -- Add the new bonus to the player
                    end
                })
                
                -- Remove this bonus from available options
                table.remove(availableBonuses, index)
            end
        end
    end
end

local function drawPlayerUpgrades()
    local padding = 10 -- Padding between elements
    local cellWidth, cellHeight = 150, 50 -- Dimensions for each cell
    local rowCount = 3 -- Number of rows

    --drawTitle
    setFont(28) -- Set font for the title
    suit.Label("Player Upgrades", {align = "center", valign = "center"}, suit.layout:row(statsWidth - 20, 60)) -- Title row
    
    -- Define the order of keys for Player.bonuses
    local rowCount = math.ceil((#Player.bonusOrder)/3)

    local intIndex = 1

    local currentRow = 0

    for i=1, math.max(rowCount,1), 1 do -- for each row
        local x, y = suit.layout:nextRow()

        local bonusLayout = {
            min_width = statsWidth - 20, -- Minimum width for the layout
            pos = {x, y}, -- Starting position (x, y)
            padding = {padding, padding}, -- Padding between cells
        }

        local colsOnThisRow = math.min(3, #Player.bonusOrder-intIndex+2)

        for i=1, colsOnThisRow, 1 do
            table.insert(bonusLayout, {"fill", 30})
        end
        local definition = suit.layout:cols(bonusLayout) -- Create a column layout for the bonuses

        currentRow = 0
        for i=1, math.min(colsOnThisRow, #Player.bonusOrder-intIndex+1), 1 do
            currentRow = currentRow + 1
            local bonusName = Player.bonusOrder[intIndex] -- Get the bonus name
            local x,y,w,h = definition.cell(i)
            suit.layout:reset(x, y, padding, padding) -- Reset layout with padding

            setFont(18) -- Set font for the stats
            suit.Label(Player.bonusOrder[intIndex], {align = "center"}, suit.layout:row(w, h)) -- Display the stat name
            setFont(16) -- Set font for the stats
            suit.layout:padding(0, 0) -- Reset padding
            suit.Label(tostring(Player.bonuses[bonusName] or 0), {align = "center"}, suit.layout:row(w, h)) -- Display the stat value
            local buttonID = generateNextButtonID()
            suit.layout:padding(0, 0) -- Reset padding
            suit.layout:row((w-30)/2, w) -- makes sure the button is centered even though it is smaller
            if suit.Button("+", {id = buttonID, align = "center"}, suit.layout:col(buttonWidth, buttonHeight)).hit then -- Display the button for upgrading the stat
                -- Check if the player has enough money to upgrade
                if Player.money < Player.bonusPrice[bonusName] then
                    print("Not enough money to upgrade " .. bonusName)
                else
                    -- Apply the upgrade
                    print(bonusName)
                    Player.bonusUpgrades[bonusName]() -- Call the upgrade function
                    Player.pay(Player.bonusPrice[bonusName]) -- Deduct the cost from the player's money
                    Player.bonusPrice[bonusName] = Player.bonusPrice[bonusName] * 5 -- Double the price for the next upgrade
                    print(bonusName .. " upgraded to " .. Player.bonuses[bonusName])
                end
            end
            setFont(16)
            suit.Label(formatNumber(Player.bonusPrice[bonusName]) .. " $", {align = "left"}, suit.layout:col(w/2-buttonWidth+10, buttonHeight)) -- Display the cost of the upgrade
            intIndex = intIndex + 1
        end
        if currentRow < 3 then
            local buttonID = generateNextButtonID()
            local x,y,w,h = definition.cell(currentRow+1)
            suit.layout:reset(x, y, padding, padding)
            setFont(22)
            if suit.Button("add stat", {id = buttonID, align = "center"}, suit.layout:row(w, h*3/2)).hit and Player.money >= Player.newUpgradePrice then
                Player.newUpgradePrice = Player.newUpgradePrice * Player.upgradePriceMultScaling
                setLevelUpShop(false) -- Set the level up shop with ball unlockedBallTypes
                Player.levelingUp = true -- Set the flag to indicate leveling up
                end
            setFont(16)
            suit.Label(formatNumber(Player.newUpgradePrice) .. " $", {align = "center"}, suit.layout:row(w, 15)) -- Display the cost of the upgrade
        elseif i == math.max(rowCount,1) then
            local x, y = suit.layout:nextRow()
            suit.layout:reset(10, y + 10, padding, padding)
            setFont(22)
            if suit.Button("add stat", {id = buttonID, align = "center"}, suit.layout:row(statsWidth - 20, 45)).hit and Player.money >= Player.newUpgradePrice then
                Player.newUpgradePrice = Player.newUpgradePrice * Player.upgradePriceMultScaling
                setLevelUpShop(false) -- Set the level up shop with ball unlockedBallTypes
                Player.levelingUp = true -- Set the flag to indicate leveling up
            end
            setFont(16)
            suit.Label(formatNumber(Player.newUpgradePrice) .. " $", {align = "center"}, suit.layout:row(statsWidth - 20, 15)) -- Display the cost of the upgrade
        end
        local x,y = suit.layout:nextRow()
        suit.layout:reset(x, y + 10, padding, padding)
        suit.layout:reset(0, y, 0, 0)
        suit.layout:row(statsWidth, 5) -- Add spacing for the separator
    end
    
    local x,y = suit.layout:nextRow()
    love.graphics.setColor(0.8, 0.8, 0.8, 1) -- Light gray
    love.graphics.rectangle("fill", 0, y + 10, statsWidth, 2) -- Horizontal line
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
end

local function drawBallStats()  
    local x, y = suit.layout:nextRow() -- Get the next row position
    local x, y = screenWidth - statsWidth + 10, 10 -- Starting position for the ball stats
    local w, h
    -- Initialize the layout with the starting position and padding
    suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)

    --draw Title
    setFont(28) -- Set font for the title
    love.graphics.draw(uiLabelImg, screenWidth-statsWidth/2-140*1.1, -12,0,1.1,1.1)
    suit.Label("Ball Types", {align = "center"}, screenWidth-statsWidth/2-140*1.1, 5, 280 * 1.1, 30)
    suit.layout:row(statsWidth, 60)
    local x,y = suit.layout:nextRow()


    -- Iterate through all balls and display their stats
    local i = 0
    for ballName, ballType in pairs(Balls.getUnlockedBallTypes()) do
        i = i + 1

        suit.layout:reset(x, y, 10, 10)

        -- draw window
        love.graphics.draw(uiWindowImg, x-25,y)    

        -- draw title label and title
        setFont(26)
        love.graphics.draw(uiLabelImg, x + statsWidth/2-uiLabelImg:getWidth()/2-10, y-20)
        setFont(getMaxFittingFontSize(ballType.name or "Unk", 30, uiLabelImg:getWidth()-30))
        suit.Label(ballType.name or "Unk", {align = "center"}, x + statsWidth/2-uiLabelImg:getWidth()/2-7, y-20, uiLabelImg:getWidth(), uiLabelImg:getHeight())

        -- print type
        setFont(20)
        local typeColor = {normal = {fg = {0.6,0.6,0.6,1}}}
        y = y + uiLabelImg:getHeight()/2
        suit.Label(ballType.type or "Unk type", {color = typeColor, align = "center"}, x + statsWidth/2-50-7, y, 100, 50)

        -- print price
        setFont(50)
        local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(ballType.price))/2
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(formatNumber(ballType.price) .. "$",x + statsWidth/2 + 104 +moneyOffsetX, y+4, math.rad(5))
        love.graphics.setColor(14/255, 164/255, 76/255,1)
        love.graphics.print(formatNumber(ballType.price) .. "$",x + statsWidth/2 + 100 +moneyOffsetX, y, math.rad(5))
        love.graphics.setColor(1,1,1,1)

        y = y + 20
        x = x + 10
        if #Balls.getUnlockedBallTypes() > 1 then
        end
        local myLayout = {
            min_width = 410, -- Minimum width for the layout
            pos = {x, y + 40}, -- Starting position (x, y)
            padding = {5, 5}, -- Padding between cells
        }
        -- Calculate the number of rows needed for the stats
        local rowCount = (ballType.noAmount or false) and countStringKeys(ballType.stats) or countStringKeys(ballType.stats) + 1
        for x = 1,  rowCount do -- adds a {"fill"} for each stat in the ballType.stats table
            table.insert(myLayout, {"fill", 30}) -- for stats
        end
        local definition = suit.layout:cols(myLayout)
        x, y, w, h = definition.cell(1)
        suit.layout:reset(10, y, 10, 10) -- Set padding (10px horizontal and vertical)
        suit.layout:row(w, h)

        -- Draw upgrade buttons for each stat
        local intIndex = 1 -- keeps track of the current cell int id being checked
        -- Define the order of keys
        local statOrder = { "amount", "damage", "speed", "cooldown", "range", "fireRate", "ammo"} -- Order of stats to display

        -- makes sure amount is only called on things that use it
        local typeStats = {} -- Initialize the typeStats table
        if ballType.noAmount == false then
           typeStats = { amount = ballType.amount } -- Start with amount
        end
        for statName, statValue in pairs(ballType.stats) do
            typeStats[statName] = statValue -- Add stats to the table
        end

        -- loops over each stats
        for _, statName in ipairs(statOrder) do
            local statValue = nil
            -- makes speed display as low value
            if typeStats[statName] then
                if statName == "speed" then
                    statValue = typeStats[statName]/50 -- Add speed to the stats table
                else
                    statValue = typeStats[statName]
                end
            end
            if statValue then -- Only process if the stat exists
                local buttonResult = nil
                x, y, w, h = definition.cell(intIndex)
                suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)
                setFont(20)

                local cellWidth = (430-10*rowCount)/rowCount
                local fontSize = getMaxFittingFontSize(tostring(shortStatNames[statName] or ""), 20, cellWidth)
                setFont(fontSize)
                
                -- draw value
                setFont(35)
                suit.layout:padding(0, 0)
                suit.Label(tostring(statValue + ((Player.bonuses[statName] or 0) or 0)), {align = "center"}, x, y-25, cellWidth, 100) -- Display the stat value

                -- draw stat icon
                local iconX = x + cellWidth/2 - iconsImg[statName]:getWidth()*1.75/2
                love.graphics.draw(iconsImg[statName], iconX, y + 75,0,1.75,1.75)

                -- draw seperator
                if _ < rowCount then
                    love.graphics.setColor(0.5,0.5,0.5,1)
                    love.graphics.rectangle("fill", x + cellWidth, y, 1, 125)
                    love.graphics.setColor(1,1,1,1)
                end

                -- draw invis button
                local invisButtonColor = {
                    normal  = {bg = {0,0,0,0}, fg = {0,0,0}},           -- invisible bg, black fg
                    hovered = {bg = {0.19,0.6,0.73,0.2}, fg = {1,1,1}}, -- glowing bg, white fg
                    active  = {bg = {1,0.6,0}, fg = {1,1,1}}          -- faint bg, white fg
                }
                local buttonID
                buttonID = generateNextButtonID() -- Generate a unique ID for the button
                local upgradeStatButton = dress:Button("", {color = invisButtonColor, id = buttonID}, x, y-10, cellWidth, 150)
                if upgradeStatButton.hit then
                    if Player.money < ballType.price then
                            print("Not enough money to upgrade " .. ballType.name .. "'s " .. statName)
                    else
                        setFont(16)
                        local stat = ballType.stats[statName] -- Get the current stat value
                        if Player.bonuses[statName] then
                            stat = stat + Player.bonuses[statName] -- Add the bonus value if it exists
                        end
                        if statName == "speed" then
                            ballType.stats.speed = ballType.stats.speed + 50 -- Example action
                            Balls.adjustSpeed(ballType.name) -- Adjust the speed of the ball
                        elseif statName == "amount" then
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
                elseif upgradeStatButton.entered then
                    currentlyHoveredButton = upgradeStatButton
                elseif upgradeStatButton.left and currentlyHoveredButton.id == upgradeStatButton.id then
                    currentlyHoveredButton = nil
                end
                intIndex = intIndex + 1
            end
        end
        suit.layout:row(statsWidth, 20) -- Add spacing for the separator
        x, y = suit.layout:nextRow()
        --if it isnt the last ballType, add a seperator
        y = y + 150 -- Add padding to the y position for the next row
        x = screenWidth - statsWidth + 10 -- Reset x position for the next ball type
    end
    if not (tableLength(Balls.getUnlockedBallTypes()) >= 5) then
        suit.layout:reset(x, y, 10, 10)
        -- Button to unlock a new ball type
        setFont(16)
        if suit.Button("Unlock new ball", {align = "center"}, suit.layout:row(statsWidth-40, 40)).hit and Player.money >= Balls.getNextBallPrice() then
            Player.pay(Balls.getNextBallPrice())
            Balls.NextBallPriceIncrease()
            setLevelUpShop(true) -- Set the level up shop with ball unlockedBallTypes
            Player.levelingUp = true -- Set the flag to indicate leveling up
        end
        suit.Label(formatNumber(Balls.getNextBallPrice()) .. " $", {color = "money", align = "center"}, suit.layout:row(statsWidth-40, 40)) -- Display the cost of the upgrade
    end
end

local function drawLevelUpShop()
    -- Initialize layout for the buttons
    local buttonWidth = (love.graphics.getWidth() - 300) / 3 - 60
    local buttonHeight = love.graphics.getHeight() - 200
    local buttonY = 100

    for index, currentUpgrade in ipairs(displayedUpgrades) do
        -- Calculate button position
        local buttonX = 175 + (index - 1) * ((love.graphics.getWidth() - 300) / 3)

        -- Use suit to create a button
        suit.layout:reset(buttonX, buttonY, 10, 10) -- Reset layout for each button
        setFont(35)
        dress:Label(currentUpgrade.name, {align = "center"}, suit.layout:row(buttonWidth, 100)) -- Display the button label
        setFont(24)
        dress:Label(currentUpgrade.description, {align = "center"}, suit.layout:row(buttonWidth, buttonHeight - 100)) -- Display the button description

        -- Use the upgrade's index as the button ID to ensure uniqueness
        local buttonID = "upgrade_" .. index
        suit.layout:reset(buttonX, buttonY, 10, 10) -- Reset layout for each button
        if suit.Button("", {id = buttonID, align = "center"}, suit.layout:col(buttonWidth, buttonHeight)).hit then
            -- Button clicked: apply the effect and close the shop
            print("Clicked on upgrade: " .. currentUpgrade.name)
            currentUpgrade.effect() -- Apply the effect of the upgrade
            Player.levelingUp = false -- Close the level up shop
            print("levelingup : "..tostring(Player.levelingUp) )
            break
        end
    end
    local x, y = suit.layout:nextRow()
    local x = screenWidth/2 - 150
    local w, h = 250, 75 -- Dimensions for the reroll button
    local buttonID = "reroll_button" -- Unique ID for the reroll button
    suit.layout:reset(x, y, 10, 10) -- Reset layout for the reroll button
    setFont(30)
    if suit.Button("Reroll", {id = buttonID, align = "center"}, suit.layout:row(w,h)).hit then
        local isBallShop = levelUpShopType == "ball"
        setLevelUpShop(isBallShop) -- Reroll the upgrades
    end

end

function upgradesUI.draw()
    if Player.levelingUp then
        print("Player.levelingUp: " .. tostring(Player.levelingUp))
        drawLevelUpShop()
        suit.layout:reset()
    else

    end

    drawPlayerStats() -- Draw the player stats table
    drawPlayerUpgrades() -- Draw the player upgrades table
    drawBallStats() -- Draw the ball stats table

    -- Draw separator lines
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.min(math.max(0, 1-math.abs(Balls.getMinX()-statsWidth)/100), 1)) -- Light gray
    love.graphics.rectangle("fill", statsWidth, 0, 1, screenHeight) -- Separator line
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.min(math.max(0, 1-math.abs(Balls.getMaxX()-(screenWidth - statsWidth))/100), 1))
    love.graphics.rectangle("fill", screenWidth - statsWidth, 0, 1, screenHeight)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
end

return upgradesUI
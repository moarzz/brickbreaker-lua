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

local invisButtonColor = {
                    normal  = {bg = {0,0,0,0}, fg = {1,1,1}},           -- invisible bg, black fg
                    hovered = {bg = {0.19,0.6,0.73,0.2}, fg = {1,1,1}}, -- glowing bg, white fg
                    active  = {bg = {1,0.6,0}, fg = {1,1,1}}          -- faint bg, white fg
                }

local buttonWidth, buttonHeight = 25, 25 -- Dimensions for each button

local upgradesQueue = {}
function upgradesUI.queueUpgrade(upgradePrice)
    table.insert(upgradesQueue, currentlyHoveredButton)
end


function upgradesUI.tryQueue()
    for x = #upgradesQueue, 1, -1 do
        if upgradesQueue[x]() then
            table.remove(upgradesQueue, x)
        end
    end
end

local drawPlayerStatsHeight = 200 -- Height of the player stats section
local function drawPlayerStats()
    love.graphics.draw(uiWindowImg, -13, -125) -- Draw the background window image

    -- Initialize the layout for the stats section
    local x, y = 10, 20
    local padding = 10 

    -- Draw the "Stats" title header
    suit.layout:reset(x, y, padding, padding) -- Reset layout with padding

    local statsLayout = {
        min_width = 430, -- Minimum width for the layout
        pos = {x, y}, -- Starting position (x, y)
        padding = {padding, padding}, -- Padding between cells
        {"fill", 30},
        {"fill"}
    }

    local definition = suit.layout:cols(statsLayout) -- Create a column layout for the stats

    -- Draw the stats details
    setFont(25) -- Set font for the stats
    local x, y, w, h = definition.cell(1)
    suit.Label("Lives", {align = "center"}, x, y, w, h)
    suit.Label(Player.lives or 3, {align = "center"}, x, y + 30, w, h) -- Display the number of lives

    -- render money
    local x, y, w, h = definition.cell(2)
    suit.Label("Money", {align = "center"}, x, y, w, h)
    setFont(45)
    local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(Player.money))/2
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(formatNumber(Player.money) .. "$",x + 104 +moneyOffsetX, y+30, math.rad(1.5))
    local moneyColor = {14/255, 202/255, 92/255,1}
    love.graphics.setColor(moneyColor)
    love.graphics.print(formatNumber(Player.money) .. "$",x + 100 + moneyOffsetX, y + 26, math.rad(1.5))
    love.graphics.setColor(1,1,1,1)

    -- Add a separator line for better visual clarity
    suit.layout:row(statsWidth, 65) -- Add spacing for the separator
    local x,y = suit.layout:nextRow()
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
                        Player.bonusUpgrades[currentBonus.name]() -- Call the upgrade function
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
    local cellWidth, cellHeight = 200, 50 -- Dimensions for each cell
    local rowCount = 3 -- Number of rows

    --drawTitle
    setFont(28) -- Set font for the title
    local x,y,w,h = suit.layout:nextRow(statsWidth - 20, 60)
    love.graphics.draw(uiBigWindowImg, 0, y +25) -- Draw the background window image
    love.graphics.draw(uiLabelImg, x+15, y,0,1.5,1) -- Draw the title background image
    suit.Label("Player Upgrades", {align = "center", valign = "center"}, suit.layout:row(statsWidth - 20, 60)) -- Title row
    
    -- Define the order of keys for Player.bonuses
    local rowCount = math.ceil((#Player.bonusOrder)/2)

    local intIndex = 1
    local currentRow = 0
    local currentCol = 0

    for i=1, math.max(rowCount,1), 1 do -- for each row
        currentRow = currentRow + 1
        local x, y = suit.layout:nextRow()

        local bonusLayout = {
            min_width = statsWidth - 20, -- Minimum width for the layout
            pos = {x, y}, -- Starting position (x, y)   
            padding = {padding, padding}, -- Padding between cells
        }

        local colsOnThisRow = math.min(2, #Player.bonusOrder-intIndex+2)

        for i=1, colsOnThisRow, 1 do
            table.insert(bonusLayout, {"fill", 30})
        end
        local definition = suit.layout:cols(bonusLayout) -- Create a column layout for the bonuses

        currentCol = 0
        for i=1, math.min(colsOnThisRow, #Player.bonusOrder-intIndex+1), 1 do -- for each col on this row
            currentCol = currentCol + 1
            local bonusName = Player.bonusOrder[intIndex] -- Get the bonus name
            local x,y,w,h = definition.cell(i)
            suit.layout:reset(x, y, padding, padding) -- Reset layout with padding

            local statName = Player.bonusOrder[intIndex]

            -- render price
            setFont(45)
            local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(Player.bonusPrice[bonusName]))/2
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(formatNumber(Player.bonusPrice[bonusName]) .. "$",x + 104 +moneyOffsetX, y+4, math.rad(5))
            local moneyColor = Player.money >= Player.bonusPrice[bonusName] and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
            love.graphics.setColor(moneyColor)
            love.graphics.print(formatNumber(Player.bonusPrice[bonusName]) .. "$",x + 100 + moneyOffsetX, y, math.rad(5))
            love.graphics.setColor(1,1,1,1)

            -- draw value
            setFont(35)
            suit.layout:padding(0, 0)
            suit.Label(tostring("+ " .. tostring(Player.bonuses[bonusName] or 0)), {align = "center"}, x, y+50, cellWidth, 100) -- Display the stat value

            -- draw stat icon
            local iconX = x + cellWidth/2 - iconsImg[statName]:getWidth()*1.75/2
            love.graphics.draw(iconsImg[statName], iconX, y + 125,0,1.75,1.75)
            y= y + 25

            -- draw seperator
            if i == 1 then
                love.graphics.setColor(0.5,0.5,0.5,1)
                love.graphics.rectangle("fill", x + cellWidth + 15, y + 10, 1, 125)
                love.graphics.setColor(1,1,1,1)
            end

            -- horizontal seperator
            if currentRow > 1 then
                love.graphics.setColor(0.5,0.5,0.5,1)
                love.graphics.rectangle("fill", x + 45, y-35, 125, 1)
                love.graphics.setColor(1,1,1,1)
            end

            local buttonID
            buttonID = generateNextButtonID() -- Generate a unique ID for the button
            local upgradeStatButton = dress:Button("", {color = invisButtonColor, id = buttonID}, x+5, y-20, cellWidth, cellHeight*4)
            if upgradeStatButton.hit then -- Display the button for upgrading the stat
                -- Check if the player has enough money to upgrade

                if Player.money < Player.bonusPrice[bonusName] then
                    print("Not enough money to upgrade " .. bonusName)
                else
                    if bonusName == "ammo" then
                        for _, ballType in pairs(Balls.getUnlockedBallTypes()) do
                            if ballType.name == "gun" then
                                ballType.currentAmmo = ballType.currentAmmo + 1 -- Increase ammo by 1
                            end
                        end
                    end
                    -- Apply the upgrade
                    print(bonusName)
                    Player.bonusUpgrades[bonusName]() -- Call the upgrade function
                    Player.pay(Player.bonusPrice[bonusName]) -- Deduct the cost from the player's money
                    Player.bonusPrice[bonusName] = Player.bonusPrice[bonusName] * 10 -- Double the price for the next upgrade
                    print(bonusName .. " upgraded to " .. Player.bonuses[bonusName])
                end
            end
            intIndex = intIndex + 1
        end
        if intIndex < 5 then
            if currentCol < 2 then
                local buttonID = generateNextButtonID()
                local x,y,w,h = definition.cell(currentCol+1)
                suit.layout:reset(x, y, padding, padding)
                setFont(30)
                if suit.Button("add stat", {color = invisButtonColor, id = buttonID, align = "center"}, suit.layout:row(w, cellHeight*4)).hit and Player.money >= Player.newUpgradePrice then
                    Player.pay(Player.newUpgradePrice) -- Deduct the cost from the player's money
                    Player.newUpgradePrice = Player.newUpgradePrice * Player.upgradePriceMultScaling
                    setLevelUpShop(false) -- Set the level up shop with ball unlockedBallTypes
                    Player.levelingUp = true -- Set the flag to indicate leveling up
                    end
                setFont(16)

                -- render price
                setFont(45)
                local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(Player.newUpgradePrice))/2
                love.graphics.setColor(0,0,0,1)
                love.graphics.print(formatNumber(Player.newUpgradePrice) .. "$",x + 104 + moneyOffsetX, y+4, math.rad(5))
                local moneyColor = Player.money >= Player.newUpgradePrice and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
                love.graphics.setColor(moneyColor)
                love.graphics.print(formatNumber(Player.newUpgradePrice) .. "$",x + 100 + moneyOffsetX, y, math.rad(5))
                love.graphics.setColor(1,1,1,1)
            elseif i == math.max(rowCount,1) then
                y = y + 210 -- Add padding to the y position for the next row
                suit.layout:reset(10, y + 10, padding, padding)
                setFont(30)
                if suit.Button("add stat", {color = invisButtonColor, id = buttonID, align = "center"}, suit.layout:row(statsWidth - 20, cellHeight*4)).hit and Player.money >= Player.newUpgradePrice then
                    Player.newUpgradePrice = Player.newUpgradePrice * Player.upgradePriceMultScaling
                    setLevelUpShop(false) -- Set the level up shop with ball unlockedBallTypes
                    Player.levelingUp = true -- Set the flag to indicate leveling up
                    Player.pay(Player.newUpgradePrice) -- Deduct the cost from the player's money
                end
                setFont(16)

                -- render price
                setFont(45)
                local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(Player.newUpgradePrice))/2
                love.graphics.setColor(0,0,0,1)
                love.graphics.print(formatNumber(Player.newUpgradePrice) .. "$",x + 104 + moneyOffsetX, y+4, math.rad(5))
                local moneyColor = Player.money >= Player.newUpgradePrice and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
                love.graphics.setColor(moneyColor)
                love.graphics.print(formatNumber(Player.newUpgradePrice) .. "$",x + 100 + moneyOffsetX, y, math.rad(5))
                love.graphics.setColor(1,1,1,1)
            end
        end
        y = y + 210
        suit.layout:reset(10, y, 0, 0)
        suit.layout:row(statsWidth, 5) -- Add spacing for the separator
    end
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
        love.graphics.draw(uiLabelImg, x + statsWidth/2-uiLabelImg:getWidth()/2-10, y-25)
        setFont(getMaxFittingFontSize(ballType.name or "Unk", 30, uiLabelImg:getWidth()-30))
        suit.Label(ballType.name or "Unk", {align = "center"}, x + statsWidth/2-uiLabelImg:getWidth()/2-7, y-25, uiLabelImg:getWidth(), uiLabelImg:getHeight())

        -- type label
        setFont(20)
        local typeColor = {normal = {fg = {0.6,0.6,0.6,1}}}
        y = y + uiLabelImg:getHeight()/2
        suit.Label(ballType.type or "Unk type", {color = typeColor, align = "center"}, x + statsWidth/2-50-7, y, 100, 50)

        -- price label
        setFont(50)
        local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(ballType.price))/2
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(formatNumber(ballType.price) .. "$",x + statsWidth/2 + 104 +moneyOffsetX, y+4, math.rad(5))
        local moneyColor = Player.money >= ballType.price and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
        love.graphics.setColor(moneyColor)
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
                
                -- draw value
                setFont(35)
                suit.layout:padding(0, 0)
                if statName == "damage" then
                    if ballType.type == "ball" and Player.bonuses["ballDamage"] then
                        statValue = statValue + Player.bonuses["ballDamage"] -- Add the bonus value if it exists
                    elseif ballType.type == "gun" and Player.bonuses["bulletDamage"] then
                        statValue = statValue + Player.bonuses["bulletDamage"] -- Add the bonus value if it exists
                    end
                end
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
                            if ballType.stats.cooldown > 1 then -- Prevent cooldown from going to 0 or below
                                ballType.stats.cooldown = ballType.stats.cooldown - 1
                                print( "stat ".. statName .. " decreased to " .. ballType.stats[statName])
                            else
                                print(ballType.name .. "'s cooldown cannot be lowered any further")
                                return false
                            end
                        elseif statName == "ammo" then
                            ballType.currentAmmo = ballType.currentAmmo + 1 -- Increase ammo by 1
                            ballType.stats[statName] = ballType.stats[statName] + 1 -- Example action
                        else
                            ballType.stats[statName] = ballType.stats[statName] + 1 -- Example action
                            print( "stat ".. statName .. " increased to " .. ballType.stats[statName])
                        end
                        Player.pay(ballType.price) -- Deduct the cost from the player's money
                        ballType.price = ballType.price * 2 -- Increase the price of the ball
                    end
                elseif upgradeStatButton.entered then
                    print("entered button")
                    currentlyHoveredButton = function() if Player.money < ballType.price then
                            print("Not enough money to upgrade " .. ballType.name .. "'s " .. statName)
                            return false
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
                            if ballType.stats.cooldown > 1 then -- Prevent cooldown from going to 0 or below
                                ballType.stats.cooldown = ballType.stats.cooldown - 1
                                print( "stat ".. statName .. " decreased to " .. ballType.stats[statName])
                            else
                                print(ballType.name .. "'s cooldown cannot be lowered any further")
                                return false
                            end
                        else
                            ballType.stats[statName] = ballType.stats[statName] + 1 -- Example action
                            print( "stat ".. statName .. " increased to " .. ballType.stats[statName])
                        end
                        Player.pay(ballType.price) -- Deduct the cost from the player's money
                        ballType.price = ballType.price * 2 -- Increase the price of the ball
                        return true
                    end end
                    --currentlyHoveredButton.price = ballType.price
                elseif upgradeStatButton.left then 
                    print("exited button id : " .. upgradeStatButton.id)
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
        if suit.Button("Unlock new weapon", {align = "center"}, suit.layout:row(statsWidth-40, 40)).hit and Player.money >= Balls.getNextBallPrice() then
            Player.pay(Balls.getNextBallPrice())
            Balls.NextBallPriceIncrease()
            setLevelUpShop(true) -- Set the level up shop with ball unlockedBallTypes
            Player.levelingUp = true -- Set the flag to indicate leveling up
        end
        suit.Label(formatNumber(Balls.getNextBallPrice()) .. " $", {color = "money", align = "center"}, suit.layout:row(statsWidth-40, 40)) -- Display the cost of the upgrade
    end
end

local function drawPerks()
    local padding = 10 -- Padding between elements
    local cellWidth, cellHeight = 200, 50 -- Dimensions for each cell
    local rowCount = 3 -- Number of rows

    --drawTitle
    setFont(28) -- Set font for the title
    local x,y,w,h = suit.layout:nextRow(statsWidth - 20, 60)
    y = y + 200 -- Adjust y position for the title
    suit.layout:reset(x, y, padding, padding) -- Reset layout with padding
    love.graphics.draw(uiBigWindowImg, 0, y +25) -- Draw the background window image
    love.graphics.draw(uiLabelImg, x+15, y,0,1.5,1) -- Draw the title background image
    suit.Label("Player Upgrades", {align = "center", valign = "center"}, suit.layout:row(statsWidth - 20, 60)) -- Title row
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
    end

    drawPlayerStats() -- Draw the player stats table
    drawPlayerUpgrades() -- Draw the player upgrades table
    --drawPerks() -- Draw the special upgrades table
    drawBallStats() -- Draw the ball stats table

    -- Draw separator lines
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.max(math.min(math.max(0, 1-math.abs(Balls.getMinX()-statsWidth)/100), 1),math.min(math.max(0, 1-math.abs(paddle.x-statsWidth)/100), 1))) -- Light gray
    love.graphics.rectangle("fill", statsWidth, 0, 1, screenHeight) -- Separator line
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.max(math.min(math.max(0, 1-math.abs(Balls.getMaxX()-(screenWidth - statsWidth))/100), 1), math.min(math.max(0, 1-math.abs(paddle.x + paddle.width-(screenWidth - statsWidth))/100))))
    love.graphics.rectangle("fill", screenWidth - statsWidth, 0, 1, screenHeight)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
end

return upgradesUI
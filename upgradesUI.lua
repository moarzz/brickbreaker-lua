-- Price for unlocking a new spell
Player = Player or {currentCore = "Bouncy Core"} -- Ensure Player table exists
local newSpellPrice = 10000

-- Helper: get unlocked spells (assuming Balls.getUnlockedBallTypes returns all, filter for type=="spell")
local function getUnlockedSpells()
    local spells = {}
    for _, ballType in pairs(Balls.getUnlockedBallTypes()) do
        if ballType.type == "spell" then
            table.insert(spells, ballType)
        end
    end
    return spells
end

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

    -- Initialize the layout for the stats section
    local x, y = screenWidth/2 - uiWindowImg:getWidth()/2, screenHeight - uiWindowImg:getHeight() + 60
    --love.graphics.draw(uiWindowImg, x, y) -- Draw the background window image
    local padding = 10
    x = x + 20
    y = y + 40

    -- Draw the "Stats" title header
    suit.layout:reset(x, y, padding, padding) -- Reset layout with padding
    local xx = x
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
    --suit.Label("Lives", {align = "center"}, x, y, w, h)
    love.graphics.setColor(1, 100/255, 100/255, 1) -- Set color for the lives text
    -- Change this suit.Label to love.graphics.print
    local livesText = tostring(Player.lives or 3)
    local textWidth = love.graphics.getFont():getWidth(livesText)
    setFont(35)
    --love.graphics.print(livesText, x + (w - textWidth)/2, y + 30)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white

    -- render money
    local x, y, w, h = definition.cell(2)
    setFont(25) 
    --suit.Label("Money", {align = "center"}, x, y, w, h)
    setFont(80)
    love.graphics.setColor(1,1,1,1)
    x,y = statsWidth/2 - getTextSize(formatNumber(Player.money))/2 - 100, 175 - love.graphics.getFont():getHeight()/2 -- Adjust position for better alignment
    local moneyOffsetX = 0---math.cos(math.rad(5))*getTextSize(formatNumber(Player.money))/2
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(formatNumber(Player.money) .. "$",x + 104 +moneyOffsetX, y +5, math.rad(1.5))
    local moneyColor = {14/255, 202/255, 92/255,1}
    love.graphics.setColor(moneyColor)
    love.graphics.print(formatNumber(Player.money) .. "$",x + 100 + moneyOffsetX, y + 1, math.rad(1.5))
    love.graphics.setColor(1,1,1,1)
    setFont(25)
    love.graphics.setColor(99/255, 170/255, 1, 1)
    setFont(35)
    x, y = statsWidth - getTextSize(formatNumber(Player.score.. " pts"))/2 + 250, 30
    --love.graphics.print(formatNumber(Player.score).. " pts", x, y, math.rad(1.5)) -- Display the score
    love.graphics.setColor(1, 1, 1, 1)

    --[[if Player.bricksDestroyed then
        setFont(28)
        local text = "Bricks Destroyed : " .. formatNumber(Player.bricksDestroyed)
        love.graphics.setColor(0, 0, 0, 0.7)
        local tw = love.graphics.getFont():getWidth(text)
        local th = love.graphics.getFont():getHeight()
        love.graphics.setColor(1, 0.5, 0.25, 1)
        love.graphics.print(text, statsWidth/2 - tw/2, - th/2 + 320)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    end]]

    if Player.currentCore then
        setFont(38)
        local coreText = tostring(Player.currentCore)
        love.graphics.setColor(0, 0, 0, 0.7)
        local tw = love.graphics.getFont():getWidth(coreText)
        local th = love.graphics.getFont():getHeight()
        -- Centered under Bricks Destroyed (which is at x=40, y=40)
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.print(coreText, statsWidth/2 - tw/2, 40 - th/2)
        love.graphics.setColor(1, 1, 1, 1)
    end

    if Player.score then
        setFont(38)
        local text = formatNumber(Player.score) .. " pts"
        love.graphics.setColor(0, 0, 0, 0.7)
        local tw = love.graphics.getFont():getWidth(text)
        local th = love.graphics.getFont():getHeight()
        love.graphics.setColor(0.25, 0.5, 1, 1)
        love.graphics.print(text, statsWidth/2 - th/2 - 25, 315 - th/2)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    end
    -- Add a separator line for better visual clarity
    suit.layout:row(statsWidth, 65) -- Add spacing for the separator
    local x,y = suit.layout:nextRow(),y
end

local paddleSizePrice = Player.currentCore == "Economy Core" and 5 or 10
local paddleSpeedPrice = Player.currentCore == "Economy Core" and 5 or 10
function resetPaddlePrices()
    paddleSizePrice = Player.currentCore == "Economy Core" and 5 or 10
    paddleSpeedPrice = Player.currentCore == "Economy Core" and 5 or 10
end

local function drawPaddleUpgrades()
    local winX = 0
    local winY = screenHeight - uiWindowImg:getHeight() + 70
    love.graphics.draw(uiSmallWindowImg, winX, winY) -- Draw the background window image
    love.graphics.draw(uiLabelImg, winX + uiWindowImg:getWidth()/2 - 210, winY - uiLabelImg:getHeight()/2+ 10, 0, 1.5, 1) -- Draw the title background image
    setFont(25)
    suit.Label("Paddle Upgrades", {align = "center"}, winX + 10, winY - 15, uiWindowImg:getWidth() - 20, 50) -- Draw the title

    -- Button layout
    local padding = 20
    local cellWidth = (uiWindowImg:getWidth() - 3 * padding) / 2
    local cellHeight = 120
    local buttonHeight = 80
    local y = winY + 60
    local x1 = winX + padding
    local x2 = winX + cellWidth + 2 * padding

    -- PaddleSize Upgrade Button
    setFont(30)
    -- Price (top right)
    local priceText = formatNumber(paddleSizePrice) .. "$"
    local priceWidth = getTextSize(priceText)
    local priceX = x1 + cellWidth - priceWidth - 10
    local priceY = y + 10
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(priceText, priceX+2, priceY+2, math.rad(5))
    local canAffordSize = Player.money >= paddleSizePrice
    local moneyColor = canAffordSize and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
    love.graphics.setColor(moneyColor)
    love.graphics.print(priceText, priceX, priceY, math.rad(5))
    love.graphics.setColor(1,1,1,1)
    -- Icon
    if iconsImg and iconsImg["paddleSize"] then
        local iconScale = 1.75
        local iconW = iconsImg["paddleSize"]:getWidth() * iconScale
        local iconH = iconsImg["paddleSize"]:getHeight() * iconScale
        love.graphics.draw(iconsImg["paddleSize"], x1 + cellWidth/2 - iconW/2, y + 40, 0, iconScale, iconScale)
    end
    -- Value label
    setFont(35)
    local buttonID1 = generateNextButtonID()
    if suit.Button("", {color = invisButtonColor, id = buttonID1}, x1, y, cellWidth, buttonHeight).hit then
        if canAffordSize then
            Player.pay(paddleSizePrice)
            if Player.upgradePaddle then Player.upgradePaddle["paddleSize"]() end
            paddleSizePrice = paddleSizePrice * 2
        else
            print("Not enough money for paddleSize upgrade")
        end
    end

    -- Separator (vertical)
    love.graphics.setColor(0.5,0.5,0.5,1)
    love.graphics.rectangle("fill", x1 + cellWidth + padding/2, y + 10, 2, buttonHeight - 20)
    love.graphics.setColor(1,1,1,1)

    -- PaddleSpeed Upgrade Button
    setFont(30)
    local priceText2 = formatNumber(paddleSpeedPrice) .. "$"
    local priceWidth2 = getTextSize(priceText2)
    local priceX2 = x2 + cellWidth - priceWidth2 - 10
    local priceY2 = y + 10
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(priceText2, priceX2+2, priceY2+2, math.rad(5))
    local canAffordSpeed = Player.money >= paddleSpeedPrice
    local moneyColor2 = canAffordSpeed and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
    love.graphics.setColor(moneyColor2)
    love.graphics.print(priceText2, priceX2, priceY2, math.rad(5))
    love.graphics.setColor(1,1,1,1)
    -- No icon for paddleSpeed
    if iconsImg and iconsImg["paddleSpeed"] then
        local iconScale = 1.75
        local iconW = iconsImg["paddleSpeed"]:getWidth() * iconScale
        local iconH = iconsImg["paddleSpeed"]:getHeight() * iconScale
        love.graphics.draw(iconsImg["paddleSpeed"], x2 + cellWidth/2 - iconW/2, y + 40, 0, iconScale, iconScale)
    end
    -- Value label
    setFont(35)
    -- Upgrade button
    local buttonID2 = generateNextButtonID()
    if suit.Button("", {color = invisButtonColor, id = buttonID2}, x2, y, cellWidth, buttonHeight).hit then
        if canAffordSpeed then
            Player.pay(paddleSpeedPrice)
            if Player.upgradePaddle then Player.upgradePaddle["paddleSpeed"]() end
            paddleSpeedPrice = paddleSpeedPrice * 2
        else
            print("Not enough money for paddleSpeed upgrade")
        end
    end
end

--[[
local newPerkPrice = Player.currentCore == "Economy Core" and 10000 or 20000 -- Price for unlocking a new perk
local perkName = ""
local function drawPerkUpgrade()
    newPerkPrice = Player.currentCore == "Economy Core" and 10000 or 20000
    local perkamount = 0
    for _,_ in pairs(Player.perks) do
        perkamount = perkamount + 1
    end
    local uiSmallWindowW = uiWindowImg:getWidth()
    local uiSmallWindowH = uiWindowImg:getHeight()
    local winX = 0
    local winY = screenHeight - uiSmallWindowH - 100
    love.graphics.draw(uiSmallWindowImg, winX, winY)
    setFont(30)
    if perkamount == 0 then
        local angle = math.rad(1.5)
        local priceText = formatNumber(newPerkPrice) .. "$"
        local priceWidth = getTextSize(priceText)
        local priceX = winX + (uiSmallWindowW - priceWidth) / 2
        local priceY = winY + 20

        -- Draw shadow text
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(priceText, priceX + 2, priceY + 2, angle)
        -- Draw main text in money green
        local canAfford = Player.money >= newPerkPrice
        local moneyColor = canAfford and {14/255, 202/255, 92/255, 1} or {164/255, 14/255, 14/255,1}
        love.graphics.setColor(moneyColor)
        love.graphics.print(priceText, priceX, priceY, angle)
        love.graphics.setColor(1, 1, 1, 1)
        setFont(35)
        if suit.Button("Unlock new perk", {align = "center", color = invisButtonColor}, winX + 10, winY + 10, uiSmallWindowW - 20, uiSmallWindowH - 20).hit and canAfford then
            Player.pay(newPerkPrice)
            newPerkPrice = newPerkPrice * 2
            setLevelUpShop(false, true, false) -- Only show spells in the shop
            Player.levelingUp = true
        end
    else
        for perkname, _ in pairs(Player.perks) do
            print("Player perks : " .. perkname)
        end
        for perkname, _ in pairs(Player.perks) do
            love.graphics.print(perkname, winX + uiWindowImg:getWidth()/2 - getTextSize(perkname)/2, winY + uiWindowImg:getHeight()/2 - 40)
        end
    end 
end]]

local levelUpShopType = "ball"
local displayedUpgrades = {} -- This should be an array, not a table with string keys
function setLevelUpShop(isForBall, isForPerks, isForSpells)
    isForPerks = isForPerks or false -- Default to false if not provided
    isForSpells = isForSpells or false
    if isForPerks then isForBall = false end -- If perks are requested, set isForBall to false
    displayedUpgrades = {} -- Clear the displayed upgrades
    if isForSpells then
        levelUpShopType = "spell"
        -- Spell unlocks
        local unlockedSpellNames = {}
        for _, ball in pairs(Balls.getUnlockedBallTypes()) do
            if ball.type == "spell" then
                unlockedSpellNames[ball.name] = true
            end
        end
        local availableSpells = {}
        for name, ballType in pairs(Balls.getBallList()) do
            if ballType.type == "spell" and not unlockedSpellNames[name] then
                table.insert(availableSpells, ballType)
            end
        end
        -- Choose up to 3 random unowned spells to display
        local numToShow = math.min(3, #availableSpells)
        for i = 1, numToShow do
            if #availableSpells > 0 then
                local index = math.random(1, #availableSpells)
                local thisSpellType = availableSpells[index]
                table.insert(displayedUpgrades, {
                    name = thisSpellType.name,
                    description = thisSpellType.description,
                    effect = function()
                        Balls.addBall(thisSpellType.name)
                    end
                })
                table.remove(availableSpells, index)
            end
        end
    elseif isForBall then
        levelUpShopType = "ball"
        -- Ball unlocks
        local unlockedBallNames = {}
        for _, ball in pairs(Balls.getUnlockedBallTypes()) do
            unlockedBallNames[ball.name] = true
        end
        -- Only include non-spell balls
        local availableBalls = {}
        for name, ballType in pairs(Balls.getBallList()) do
            if (not unlockedBallNames[name]) then
                table.insert(availableBalls, ballType)
            end
        end
        local currentBallType = nil
        -- Choose random unowned balls to display
        for i = 1, math.min(3, #availableBalls) do
            if #availableBalls > 0 then
                local bruh = true
                local index
                while bruh do
                    bruh = false
                    index = math.random(1, #availableBalls)
                    currentBallType = availableBalls[index]
                    if unlockedBallNames[currentBallType.name] then
                        bruh = true
                    end
            local canBuy = Balls.getBallList()[currentBallType.name].canBuy
            if canBuy and not canBuy() then
                bruh = true
            end
                end
                local thisBallType = currentBallType
                table.insert(displayedUpgrades, {
                    name = thisBallType.name,
                    description = thisBallType.description,
                    effect = function()
                        print("will add ball: " .. thisBallType.name)
                        Balls.addBall(thisBallType.name)
                    end
                })
                -- Remove this ball from available options using the correct index
                table.remove(availableBalls, index)
            end
        end
    elseif isForPerks then
        -- Perk unlocks
        levelUpShopType = "perk"
        local availablePerks = {}
        for name, perk in pairs(Player.perksList) do
            if not Player.perks[name] then
                table.insert(availablePerks, perk)
            end
        end
        
        -- Choose random unowned perks
        for i = 1, math.min(3, #availablePerks) do
            if #availablePerks > 0 then
                local index = math.random(1, #availablePerks)
                local currentPerk = availablePerks[index]
                
                table.insert(displayedUpgrades, {
                    name = currentPerk.name,
                    description = currentPerk.description,
                    effect = function()
                        Player.addPerk(currentPerk.name) -- Add the new perk to the player
                        if Player.perkUpgrades[currentPerk.name] then
                            Player.perkUpgrades[currentPerk.name]() -- Call the upgrade function
                        else
                            print("Warning: No upgrade function for perk '" .. tostring(currentPerk.name) .. "'")
                        end
                    end
                })
                
                -- Remove this perk from available options
                table.remove(availablePerks, index)
            end
        end
    else
        -- Player upgrades
        local advantagiousBonuses = {}
        for _, item in pairs(Balls.getUnlockedBallTypes()) do
            for statName, stat in pairs(item.stats) do
                local doit = true
                if not Player.bonuses[statName] then
                    for _, bonus in ipairs(advantagiousBonuses) do
                        if bonus == statName and (not ((Player.currentCore == "Damage Core") and (statName == "fireRate" or statName == "amount"))) and not (Player.currentCore == "Cooldown Core" and statName == "cooldown") then
                            doit = false -- If this bonus is already in the list, skip it
                        end
                    end
                    if doit then
                        table.insert(advantagiousBonuses, statName)
                    end
                end
            end
        end
        levelUpShopType = "playerUpgrade"
        local availableBonuses = {}
        for bonusName, bonus in pairs(Player.bonusesList) do
            if (not Player.bonuses[bonusName]) and not ((Player.currentCore == "Damage Core") and (bonusName == "fireRate" or bonusName == "amount")) and not (Player.currentCore == "Cooldown Core" and bonusName == "cooldown") then
                table.insert(availableBonuses, bonusName)
            end
        end
        
        -- Choose random unowned upgrades
        for i = 1, math.min(3, #availableBonuses) do
            if #availableBonuses > 0 then
                local index = 1
                local currentBonus = nil
                print("#advantagiousBonuses: " .. #advantagiousBonuses)
                print("#availableBonuses: " .. #availableBonuses)
                if #advantagiousBonuses > 0 then
                    local bruh = true
                    while bruh do 
                        index = math.random(1, #advantagiousBonuses)
                        currentBonus = advantagiousBonuses[index]
                        for _, displayedUpgrade in ipairs(displayedUpgrades) do
                            if displayedUpgrade.name == currentBonus then
                                currentBonus = nil
                            end
                        end
                        if currentBonus ~= nil then
                            bruh = false
                        end
                    end
                    for id, bonusName in ipairs(availableBonuses) do
                        if bonusName == currentBonus then
                            availableBonuses[id] = nil
                        end
                    end
                    advantagiousBonuses[index] = nil -- Remove this bonus from the advantagiousBonuses list
                    print("true")
                else
                    local bruh = true
                    while bruh do
                        index = math.random(1, #availableBonuses)
                        currentBonus = availableBonuses[index]
                        for _, displayedUpgrade in ipairs(displayedUpgrades) do
                            if displayedUpgrade.name == currentBonus then
                                currentBonus = nil
                            end
                        end
                        if currentBonus ~= nil then
                            bruh = false
                        end
                    end
                    availableBonuses[index] = nil -- Remove this bonus from the availableBonuses list
                    print("false")
                end

                print("Current bonus: " .. tostring(currentBonus or "nil"))
                print("index: " .. tostring(index))
                table.insert(displayedUpgrades, {
                    name = Player.bonusesList[currentBonus].name,
                    description = Player.bonusesList[currentBonus].description,
                    effect = function()
                        print("Adding bonus: " .. currentBonus)
                        Player.addBonus(currentBonus) -- Add the new bonus to the player
                        Player.bonusUpgrades[currentBonus]() -- Call the upgrade function
                    end
                })
                
                -- Remove this bonus from available options
                if #advantagiousBonuses > 0 then
                    table.remove(advantagiousBonuses, index)
                else
                    table.remove(availableBonuses, index)
                end
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
    suit.layout:reset(0, -80, padding, padding) -- Reset layout with padding
    local x,y,w,h = suit.layout:row(statsWidth - 20, 60)
    y = screenHeight/2 - 190
    love.graphics.draw(uiBigWindowImg, 0, y + 25, 0, 1, 1) -- Draw the background window image
    love.graphics.draw(uiLabelImg, x+15, y,0,1.5,1) -- Draw the title background image
    suit.layout:reset(x, y, padding, padding) -- Reset layout with padding
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
            suit.Label(tostring((bonusName ~= "cooldown" and "+ " or "") .. tostring(Player.bonuses[bonusName] or 0)), {align = "center"}, x, y+50, cellWidth, 100) -- Display the stat value

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
                    -- Always pay first, then increase the price
                    Player.pay(Player.bonusPrice[bonusName]) -- Deduct the cost from the player's money
                    Player.bonusUpgrades[bonusName]() -- Call the upgrade function
                    Player.bonusPrice[bonusName] = Player.bonusPrice[bonusName] * 10 -- Increase the price for the next upgrade
                    print(bonusName .. " upgraded to " .. Player.bonuses[bonusName])
                    if bonusName == "cooldown" then
                        Balls.reduceAllCooldowns()
                    end
                    if bonusName == "ammo" then
                        for _, ball in pairs(Balls.getUnlockedBallTypes()) do
                            if ball.type == "gun" then
                                ball.currentAmmo = (ball.currentAmmo or 0) + (ball.ammoMult or 1) -- Reset ammo for all gun balls
                            end
                        end
                    end
                end
            end
            if upgradeStatButton.entered then
                hoveredStatName = statName
            elseif upgradeStatButton.left and hoveredStatName == statName then
                hoveredStatName = nil
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
    local BallsToShow = {}
    for ballName, ballType in pairs(Balls.getUnlockedBallTypes()) do
        BallsToShow[ballName] = ballType
    end
    for ballName, ballType in pairs(BallsToShow) do
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

        -- damageDealt label (top right, mirroring price)
        local damageDealt = ballType.damageDealt or 0
        local dmgText = tostring(formatNumber(damageDealt)) .. " dmg"
        local dmgOffsetX = -math.cos(math.rad(5))*getTextSize(dmgText)/2
        setFont(30)
        local dmgTextWidth = love.graphics.getFont():getWidth(dmgText)

        -- Place at top right of the window, mirroring price
        local dmgX = screenWidth - statsWidth*3/4 + 20
        local dmgY = y + 13
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(dmgText, dmgX + 4 + dmgOffsetX, dmgY + 4,math.rad(-2.5))
        love.graphics.setColor(1,0.25,0.25,1)
        love.graphics.print(dmgText, dmgX + dmgOffsetX, dmgY, math.rad(-2.5))
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
        if ballType.noAmount and ballType.stats.amount then
            rowCount = rowCount-- - 1 -- If no amount, don't count it
        end
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
                    if ballType.type == "ball" and (Player.bonuses["ballDamage"] or Player.permanentUpgrades["ballDamage"]) then
                        statValue = statValue + (Player.bonuses["ballDamage"] or 0) + (Player.permanentUpgrades["ballDamage"] or 0)
                    elseif ballType.type == "gun" and (Player.bonuses["bulletDamage"] or Player.permanentUpgrades["bulletDamage"]) then
                        statValue = statValue + (Player.bonuses["bulletDamage"] or 0) + (Player.permanentUpgrades["bulletDamage"] or 0)
                    end
                end
                -- Add permanent upgrades to the display value
                local permanentUpgradeValue = Player.permanentUpgrades[statName] or 0
                local bonusValue = Player.bonuses[statName] or 0
                local value = (Player.currentCore == "Cooldown Core" and statName == "cooldown") and 2 or statValue + bonusValue + permanentUpgradeValue
                if statName == "ammo" then
                    value = value - permanentUpgradeValue - bonusValue + bonusValue * ballType.ammoMult -- Adjust ammo value based on ammoMult
                end
                if (statName == "fireRate" or statName == "amount") and Player.currentCore == "Damage Core" then
                    value = 2
                end
                if statName == "damage" and Player.currentCore == "Damage Core" then
                    value = value * 4 -- Double damage for Damage Core
                end
                suit.Label(tostring(value), {align = "center"}, x, y-25, cellWidth, 100)

                -- draw stat icon
                local iconX = x + cellWidth/2 - iconsImg[statName]:getWidth()*1.75/2
                love.graphics.draw(iconsImg[statName], iconX, y + 75,0,1.75,1.75)

                -- draw seperator
                if intIndex < rowCount then
                    love.graphics.setColor(0.4,0.4,0.4,1)
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
                local canUpgrade = true
                if statName == "cooldown" and Player.currentCore == "Cooldown Core" then
                    canUpgrade = false -- Cannot upgrade cooldown if using Cooldown Core
                end
                if statName == "ammo" and ((ballType.stats.cooldown or 1000) + (Player.bonuses["cooldown"] or 0) + (Player.permanentUpgrades["cooldown"] or 0)) <= 0 then
                    canUpgrade = false -- Cannot upgrade ammo if cooldown is already at 0
                end
                if ((statName == "fireRate" or statName == "amount") and Player.currentCore == "Damage Core")then
                    canUpgrade = false -- Cannot upgrade fireRate or amount if using Damage Core
                end
                if upgradeStatButton.hit and canUpgrade then
                    if Player.money < ballType.price then
                            print("Not enough money to upgrade " .. ballType.name .. "'s " .. statName)
                    elseif statName == "cooldown" and statValue <= 0 then
                        print("cannot upgrade cooldown any further")
                    else
                        setFont(16)
                        print("Upgrading " .. ballType.name .. "'s " .. statName)
                        local stat = ballType.stats[statName] or 0-- Get the current stat value
                        if statName == "speed" then
                            ballType.stats.speed = ballType.stats.speed + 50 -- Example action
                            Balls.adjustSpeed(ballType.name) -- Adjust the speed of the ball
                        elseif statName == "amount" and not ballType.noAmount then
                            Balls.addBall(ballType.name, true) -- Add a new ball of the same type
                        elseif statName == "cooldown" then
                            ballType.stats.cooldown = ballType.stats.cooldown - 1
                        elseif statName == "ammo" then
                            print(ballType.name .. " ammo increased by " .. ballType.ammoMult)
                            ballType.currentAmmo = ballType.currentAmmo + ballType.ammoMult -- Increase ammo by ammoMult
                            ballType.stats.ammo = ballType.stats.ammo + ballType.ammoMult -- Example action
                        else
                            ballType.stats[statName] = ballType.stats[statName] + 1 -- Example action
                            print( "stat ".. statName .. " increased to " .. ballType.stats[statName])
                        end
                        Player.pay(ballType.price) -- Deduct the cost from the player's money
                        ballType.price = ballType.price * 2 -- Increase the price of the ball
                    end
                elseif upgradeStatButton.entered then
                    hoveredStatName = statName
                elseif upgradeStatButton.left and hoveredStatName == statName then
                    hoveredStatName = nil
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
        x = x + 15
        suit.layout:reset(x, y, 10, 10)
        love.graphics.draw(uiSmallWindowImg, x-25,y) -- Draw the background window image
        x = x - 10
        y = y + 10
        suit.layout:reset(x, y, 10, 10)
        -- Button to unlock a new ball type
        setFont(30)
        local angle = angle or math.rad(1.5) -- Default angle if not provided

        local price = Balls.getNextBallPrice()
        price = Player.currentCore == "Economy Core" and math.floor(price * 0.5) or price -- Apply Economy Core discount
        --draw money text
        x = x + (uiSmallWindowImg:getWidth() - 25)/4 * 3
        y = y + 7
        setFont(50)
        local moneyOffsetX = -math.cos(math.rad(5)) * getTextSize(formatNumber(price))/2

        -- Draw shadow text
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(formatNumber(price) .. "$", x + 4 + moneyOffsetX, y + 4, angle)

        -- Draw main text in money green
        local canAfford = Player.money >= price
        local moneyColor = canAfford and {14/255, 202/255, 92/255, 1} or {164/255, 14/255, 14/255,1}
        love.graphics.setColor(moneyColor)
        love.graphics.print(formatNumber(price) .. "$", x + moneyOffsetX, y, angle)

        -- Reset color
        love.graphics.setColor(1, 1, 1, 1)
        setFont(35)
        if suit.Button("unlock new weapon", {align = "center", color = invisButtonColor}, suit.layout:row(uiSmallWindowImg:getWidth() - 25, uiSmallWindowImg:getHeight() - 27)).hit and Player.money >= Balls.getNextBallPrice() then
                Player.pay(Balls.getNextBallPrice())
                Balls.NextBallPriceIncrease()
                setLevelUpShop(true) -- Set the level up shop with ball unlockedBallTypes
                Player.levelingUp = true -- Set the flag to indicate leveling up
        end
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
            break
        end
    end
    local x, y = suit.layout:nextRow()
    local x = screenWidth/2 - 150
    local w, h = 250, 75 -- Dimensions for the reroll button
    local buttonID = "reroll_button" -- Unique ID for the reroll button
    suit.layout:reset(x, y, 10, 10) -- Reset layout for the reroll button
    setFont(30)
    --[[if suit.Button("Reroll", {id = buttonID, align = "center"}, suit.layout:row(w,h)).hit then
        local isBallShop = levelUpShopType == "ball"
        setLevelUpShop(isBallShop) -- Reroll the upgrades
    end]]

end

function upgradesUI.draw()
    
    if Player.levelingUp then
        drawLevelUpShop()
    end

    drawPlayerStats() -- Draw the player stats table
    drawPlayerUpgrades() -- Draw the player upgrades table
    drawBallStats() -- Draw the ball stats table
    --drawPerkUpgrade() -- Draw the player perks table
    drawPaddleUpgrades()

    -- Draw separator lines
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.max(math.min(math.max(0, 1-math.abs(Balls.getMinX()-statsWidth)/100), 1),math.min(math.max(0, 1-math.abs(paddle.x-statsWidth)/100), 1))) -- Light gray
    love.graphics.rectangle("fill", statsWidth, 0, 1, screenHeight) -- Separator line
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.max(math.min(math.max(0, 1-math.abs(Balls.getMaxX()-(screenWidth - statsWidth))/100), 1), math.min(math.max(0, 1-math.abs(paddle.x + paddle.width-(screenWidth - statsWidth))/100))))
    love.graphics.rectangle("fill", screenWidth - statsWidth, 0, 1, screenHeight)
    love.graphics.setColor(0.6, 0.6, 0.6, 0.6* mapRangeClamped(math.abs(getHighestBrickY() + brickHeight - paddle.y), 0, 150, 1, 0)) -- Reset color to white
    love.graphics.rectangle("fill", statsWidth, paddle.y, screenWidth - statsWidth * 2, 1) -- Draw the paddle area
    love.graphics.setColor(1, 1, 1, 1) -- Reset color to white   
    
    -- Draw Player.bricksDestroyed at the bottom left of the screen

    -- Draw stat hover label if hovering a stat
    if hoveredStatName then
        local mx, my = love.mouse.getPosition()
        setFont(22)
        local tw = love.graphics.getFont():getWidth(hoveredStatName)
        local th = love.graphics.getFont():getHeight()
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", mx+18, my-8, tw+16, th+10, 6, 6)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(hoveredStatName, mx+26, my-4)
    end
    love.graphics.setColor(1,1,1,1)
end

return upgradesUI
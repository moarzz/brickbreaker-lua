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

local rerollPrice = 2

function setRerollPrice(price)
    rerollPrice = price
end

local queuedUpgradeAnimations = {}

-- items list
longTermInvestment = {}
longTermInvestment.value = 0
permanentItemBonuses = {}

_G.Items = require("items");


local _shared_item_fonts = _shared_item_fonts or {
    default = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 18),
    big = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 23),
    bold = love.graphics.newFont("assets/Fonts/KenneyFutureBold.ttf", 25),
}

local _shared_item_images = _shared_item_images or {}

function getItem(itemName)
    return Items.getItemByName(itemName);
    -- return items[itemName]
end

function hasItem(itemName)
    for _, item in ipairs(Player.items) do
        if item.name == itemName then
            return true
        end
    end
    return false
end

function itemCount(itemName)
    local count = 0
    for _, item in ipairs(Player.items) do
        if item.name == itemName then
            count = count + 1
        end
    end
    return count
end

function getItemsIncomeBonus()
    local incomeBonus = 0
    for itemName, item in pairs(Player.items) do
        if item.incomeBonus then
            incomeBonus = incomeBonus + item.incomeBonus
        end
    end
    return incomeBonus
end

function getStatItemBonusNoDouble(statName, weapon)
    local totalBonus = 0
    if #Player.items < 1 then return (permanentItemBonuses[statName] or 0) end
    
    -- Calculate the actual item bonus
    for itemName, item in pairs(Player.items) do
        if item.stats[statName] then
            if item.statsCondition then
                if item.statsCondition(weapon) then
                    totalBonus = totalBonus + item.stats[statName]
                end
            else
                totalBonus = totalBonus + item.stats[statName]
            end
        end
    end
    
    -- Apply minimum value logic only if weapon is provided
    if weapon then
        local weaponStatValue = 0
        if statName == "amount" and not weapon.noAmount then
            weaponStatValue = weapon.ballAmount
        elseif weapon.stats[statName] then
            weaponStatValue = weapon.stats[statName]
        end
        
        -- Calculate what the total would be with current bonus
        local permanentBonus = Player.permanentUpgrades[statName] or 0
        local currentStatValue = weaponStatValue + permanentBonus + totalBonus
        
        -- If the total would be less than 1, adjust the bonus to make it exactly 1
        local targetValue = statName == "speed" and 50 or 1
        targetValue = statName == "cooldown" and 0 or 1
        if currentStatValue < targetValue then
            totalBonus = targetValue - weaponStatValue - permanentBonus
        end
    end

    return totalBonus
end

function getStatItemsBonus(statName, weapon)
    if statDoubled ~= nil then
        print("current stat doubled : " .. statDoubled)
    end
    if accelerationOn then
        print("acceleration is on")
    end
    local totalBonus = 0
    if #Player.items < 1 and not (statDoubled == statName or ((statName == "fireRate" or statName == "speed") and accelerationOn)) then
        return (permanentItemBonuses[statName] or 0);
    end
    
    -- Calculate the actual item bonus
    for itemName, item in pairs(Player.items) do
        if item.stats[statName] then
            if item.statsCondition then
                if item.statsCondition(weapon) then
                    totalBonus = totalBonus + item.stats[statName]
                end
            else
                totalBonus = totalBonus + item.stats[statName]
            end
        end
    end

    return totalBonus
end

function itemsOnLevelUpEnd()
    for _, item in pairs(Player.items) do
        if item.onLevelUpEnd then
            item.onLevelUpEnd()
        end
    end
end
-----------------------------------

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
local totallyInvisButtonColor = {
    normal = { bg = {0,0,0,0}, fg = {0,0,0,0}},
    hovered = { bg = {0,0,0,0}, fg = {0,0,0,0}},
    active = { bg = {0,0,0,0}, fg = {0,0,0,0}}
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

visualMoneyValues = {scale = 1}
uiOffset = {x = 0, y = 0}
local drawPlayerStatsHeight = 200 -- Height of the player stats section
local playerStatsPointers = {
    default = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 20),
    big = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 26),
    bold = love.graphics.newFont("assets/Fonts/KenneyFutureBold.ttf", 28),
    -- interest = interestValue,
    -- totalInterest = gainValue
}
local popupFancyText = nil
local function drawPlayerStats()
    if not (Player.levelingUp and not Player.choosingUpgrade) then
        return
    end
    local xOffset = -uiOffset.x

    -- Initialize the layout for the stats section
    local x, y = screenWidth/2 - uiWindowImg:getWidth()/2, screenHeight - uiWindowImg:getHeight() + 60
    --love.graphics.draw(uiWindowImg, x, y) -- Draw the background window image
    local padding = 10
    x = x + 20 + xOffset
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

    setFont(80)
    x,y = statsWidth/2 - getTextSize(formatNumber(Player.realMoney))/2 - 100, 175 - love.graphics.getFont():getHeight()/2

    -- Popup on hover: explain interest system
    local moneyBoxW = getTextSize(formatNumber(Player.realMoney) .. "$")
    local moneyBoxH = love.graphics.getFont():getHeight()
    local mouseX, mouseY = love.mouse.getPosition()
    local interestValue = 0--math.floor(math.min(Player.money, Player.currentCore == "Economy Core" and 50 or 25)/5)
    local gainValue = 5 + longTermInvestment.value
    if Player.currentCore == "Loan Core" then
        gainValue = 3 + longTermInvestment.value
    end
    local popupText = "At the start of the level up phase, gain <color=money><font=big>" .. gainValue .. "$ <font=default><color=white>interest"-- </color=money></font=big><color=white><font=default> + </font=default></color=white><font=big><color=money>1$ </color=money></font=big><color=white><font=default>for every <font=big><color=money>5$</color=money></font=big><color=white><font=default> you have, max </color=white></font=default><color=money><font=big>10$ </color=money></font=big><color=white><font=default><font=default><color=white>"
    if Player.currentCore == "Loan Core" then
        popupText = "At the start of the level up phase, gain <color=money><font=big>".. gainValue .."$ <font=default><color=white>interest"
    end
    if popupFancyText == nil then
        popupFancyText = FancyText.new(popupText, 20, 15, 350, 20, "left", playerStatsPointers.default, playerStatsPointers)
    else
        popupFancyText:setText(popupText); 
    end
    love.graphics.setColor(1,1,1,1)
    popupFancyText:draw()

    -- render interest if player has not finished leveling up
    local interestValue = 5 -- + math.floor(math.min(Player.money, Player.currentCore == "Economy Core" and 50 or 25)/5) + getItemsIncomeBonus()
    if Player.currentCore == gainValue then
        interestValue = 3
    end
    --[[if Player.levelingUp and interestValue > 0 then
        setFont(45)
        love.graphics.setColor(moneyColor)
        x, y = x + 90, y - 45
        love.graphics.print("+" .. formatNumber(interestValue) .. "$",x + 100, y + 1, math.rad(1.5))
    end]]

    if Player.currentCore and Player.levelingUp and not Player.choosingUpgrade then
        --[[setFont(38)
        local coreText = tostring(Player.currentCore)
        love.graphics.setColor(0, 0, 0, 0.7)
        local tw = love.graphics.getFont():getWidth(coreText)
        local th = love.graphics.getFont():getHeight()
        -- Centered under Bricks Destroyed (which is at x=40, y=40)
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.print(coreText, screenWidth/2 - tw/2, screenHeight - th - 15)
        love.graphics.setColor(1, 1, 1, 1)]]
    end

    if Player.score then
        setFont(38)
        local text = formatNumber(Player.score) .. " pts"
        love.graphics.setColor(0, 0, 0, 0.7)
        local tw = love.graphics.getFont():getWidth(text)
        local th = love.graphics.getFont():getHeight()
        love.graphics.setColor(0.25, 0.5, 1, 1)
        love.graphics.print(text, statsWidth/2 - th/2 - 25 + xOffset, 315 - th/2)
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    end
    -- Add a separator line for better visual clarity
    suit.layout:row(statsWidth, 65) -- Add spacing for the separator
    local x,y = suit.layout:nextRow(),y
end

local function drawInterestUpgrade()
    --[[local xOffset = -uiOffset.x
    love.graphics.draw(uiWindowImg, xOffset + uiWindowImg:getWidth(), 100, 0, 0.5, 0.65)
    love.graphics.draw(uiLabelImg, xOffset + uiWindowImg:getWidth() * 1.25 - uiLabelImg:getWidth()*0.65/2, 80, 0, 0.65, 1)]]
end

local function getRarityDistributionByLevel()
    local level = Player.level
    if level < 4 then
        return {common = 1, uncommon = 0, rare = 0.0, legendary = 0.0}
    elseif level < 7 then
        return {common = 0.83, uncommon = 0.15, rare = 0.02, legendary = 0.0}
    elseif level < 11 then
        return {common = 0.675, uncommon = 0.25, rare  = 0.075, legendary = 0}
    elseif level < 15 then
        return {common = 0.6, uncommon = 0.3, rare = 0.1, legendary = 0}
    elseif level < 18 then
        return {common = 0.5, uncommon = 0.35, rare = 0.125, legendary = 0.025}
    elseif level < 23 then
        return {common = 0.475, uncommon = 0.35, rare = 0.125, legendary = 0.05}  
    else
        return {common = 0.4, uncommon = 0.39, rare = 0.15, legendary = 0.06}
    end
end

local function getRandomWeaponOfRarity(rarity)
    consumable = consumable or false
    local rarityList = {}   
    if rarity == "common" then
        rarityList = commonWeapons
    elseif rarity == "uncommon" then
        rarityList = uncommonWeapons
    elseif rarity == "rare" then
        rarityList = rareWeapons
    elseif rarity == "legendary" then
        rarityList = legendaryWeapons
    end
    if #rarityList == 0 then
        print("Error: No items available for rarity " .. rarity .. " with consumable = " .. tostring(consumable))
        local item = getRandomWeaponOfRarity("common")
        return item
    else
        print("Choosing from " .. #rarityList .. " items of rarity " .. rarity .. " with consumable = " .. tostring(consumable))
    end
    local weapon = rarityList[math.random(1, #rarityList)]
    return weapon
end

local levelUpShopType = "weapon"
local displayedUpgrades = {} -- This should be an array, not a table with string keys
local tweenSpeed = 2 -- Adjust this to control fade in speed

function setLevelUpShop()
    levelUpShopAlpha = 0
    shouldTweenAlpha = true
    displayedUpgrades = {} -- Clear the displayed upgrades
    levelUpShopType = "weapon"
    -- Ball unlocks
    local unlockedBallNames = {}
    for _, ball in pairs(Balls.getUnlockedBallTypes()) do
        unlockedBallNames[ball.name] = true
    end
    -- Only include non-spell balls
    local availableBalls = {}
    local weightedBalls = {}  -- Store balls with their weights
    local unlockedCount = #Balls.getUnlockedBallTypes()
    print("Unlocked Count: " .. unlockedCount)

    for i=1, 3 do
        local rarityDistribution = getRarityDistributionByLevel()
        local commonChance, uncommonChance, rareChance, legendaryChance = rarityDistribution.common, rarityDistribution.uncommon, rarityDistribution.rare, rarityDistribution.legendary
        
        local doAgain = true
        local iterations = 0
        local maxIterations = 100
        local iterations = 0
        local weaponToDisplay = nil
        while doAgain and iterations < maxIterations do
            local randomChance = math.random(1,100)/100
            iterations = iterations + 1
            doAgain = false
            print("Rarity chances: common=" .. tostring(commonChance) .. ", uncommon=" .. tostring(uncommonChance) .. ", rare=" .. tostring(rareChance) .. ", legendary=" .. tostring(legendaryChance))
            if randomChance <= commonChance then
                weaponToDisplay = getRandomWeaponOfRarity("common")
            elseif randomChance <= commonChance + uncommonChance then
                weaponToDisplay = getRandomWeaponOfRarity("uncommon")
            elseif randomChance <= commonChance + uncommonChance + rareChance then
                weaponToDisplay = getRandomWeaponOfRarity("rare")
            elseif randomChance <= commonChance + uncommonChance + rareChance + legendaryChance then
                weaponToDisplay = getRandomWeaponOfRarity("legendary")
            else
                weaponToDisplay = getRandomWeaponOfRarity("common")
            end

            -- Failsafe to prevent infinite loops
            if iterations > 80 then
                weaponToDisplay = getRandomWeaponOfRarity("common")
            end

            -- Ensure the weapon is not already displayed or owned
            for _, displayedWeapon in pairs(displayedUpgrades) do
                if displayedWeapon.name == weaponToDisplay.name then
                    doAgain = true
                    break
                end
            end
            for _, playerWeapon in pairs(Balls.getUnlockedBallTypes()) do
                if playerWeapon.name == weaponToDisplay.name then
                    doAgain = true
                    break
                end
            end
        end
        table.insert(displayedUpgrades, {
            name = weaponToDisplay.name,
            description = weaponToDisplay.description,
            type = weaponToDisplay.type,
            rarity = weaponToDisplay.rarity or "common",
            effect = function()
                print("will add weapon: " .. weaponToDisplay.name)
                Balls.addBall(weaponToDisplay.name)
            end
        })
        ::continue::
    end
end

addStatQueued = false -- Flag to indicate if the "add stat" button was queued
local function drawPlayerUpgrades()
    local xOffset = -uiOffset.x
    local padding = 10 -- Padding between elements
    local cellWidth, cellHeight = 200, 50 -- Dimensions for each cell
    local rowCount = 3 -- Number of rows

    --drawTitle
    setFont(28) -- Set font for the title
    suit.layout:reset(0, -80, padding, padding) -- Reset layout with padding
    local x,y,w,h = suit.layout:row(statsWidth - 20, 60)
    x = x + xOffset
    y = screenHeight/2 - 190
    love.graphics.draw(uiBigWindowImg, 0 + xOffset, y + 25, 0, 1, 1) -- Draw the background window image
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
            pos = {x + xOffset, y}, -- Starting position (x, y) with xOffset
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
            x = x + xOffset -- Apply xOffset to the cell position
            suit.layout:reset(x, y, padding, padding) -- Reset layout with padding

            local statName = Player.bonusOrder[intIndex]

            -- render price
            setFont(45)
            local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(math.ceil(Player.bonusPrice[bonusName]))) / 2
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(formatNumber(math.ceil(Player.bonusPrice[bonusName])) .. "$", x + 104 + moneyOffsetX, y+4, math.rad(5))
            local moneyColor = Player.realMoney >= Player.bonusPrice[bonusName] and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
            love.graphics.setColor(moneyColor)
            love.graphics.print(formatNumber(math.ceil(Player.bonusPrice[bonusName])) .. "$", x + 100 + moneyOffsetX, y, math.rad(5))
            love.graphics.setColor(1,1,1,1)

            -- draw value
            setFont(35)
            suit.layout:padding(0, 0)
            suit.Label(tostring((bonusName ~= "cooldown" and "+ " or "") .. tostring(Player.bonuses[bonusName] or 0)), {align = "center"}, x-5, y+50, cellWidth, 100) -- Display the stat value

            -- draw stat icon
            local iconX = x + cellWidth/2 - iconsImg[statName]:getWidth()*1.75/2
            love.graphics.draw(iconsImg[statName], iconX, y + 125, 0, 1.75, 1.75)
            y = y + 25

            -- draw separator
            if i == 1 then
                love.graphics.setColor(0.5,0.5,0.5,1)
                love.graphics.rectangle("fill", x + cellWidth, y + 10, 1, 125)
                love.graphics.setColor(1,1,1,1) -- Reset color to white
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
            -- Check if the player has enough money to upgrade
            local upgradeQueued = false
            if Player.queuedUpgrades then
                if Player.queuedUpgrades[1] == bonusName then
                    upgradeQueued = true
                end
            end
            if upgradeStatButton.hit or (upgradeQueued and Player.realMoney >= math.ceil(Player.bonusPrice[bonusName])) and (usingMoneySystem or Player.levelingUp) then
                if Player.realMoney < math.ceil(Player.bonusPrice[bonusName]) then
                    if usingMoneySystem then
                        print("Not enough money to upgrade " .. bonusName)
                        table.insert(Player.queuedUpgrades, bonusName)
                    end
                else
                    playSoundEffect(upgradeSFX, 0.5, 0.95, false)
                    if upgradeQueued then
                        -- Remove the queued upgrade if the player has enough money now
                        for i = #Player.queuedUpgrades, 1, -1 do
                            if Player.queuedUpgrades[i] == bonusName then
                                table.remove(Player.queuedUpgrades, i)
                                break
                            end
                        end
                    end
                    -- Always pay first, then increase the price
                    Player.pay(math.ceil(Player.bonusPrice[bonusName])) -- Deduct the cost from the player's money
                    Player.bonusUpgrades[bonusName]() -- Call the upgrade function
                    Player.bonusPrice[bonusName] = Player.bonusPrice[bonusName] * (usingMoneySystem and 10 or 2) -- Increase the price for the next upgrade
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
            elseif upgradeStatButton.left then
                hoveredStatName = nil
            end
            local upgradeCount = 0
            for _, queuedUpgrade in ipairs(Player.queuedUpgrades) do
                if queuedUpgrade == statName then
                    upgradeCount = upgradeCount + 1
                end
            end 
            setFont(30)
            if upgradeCount > 0 then
                love.graphics.setColor(161/255, 231/255, 1, 1)
                love.graphics.print((statName == "cooldown" and "-" or "+") .. upgradeCount, x + cellWidth/3*2 - 5, y + 35) -- Display queued upgrade count
            end
            love.graphics.setColor(1,1,1,1)

            if love.mouse.getX() < x+5 + cellWidth and love.mouse.getX() > x+5 and love.mouse.getY() < y-20 + cellHeight*4 and love.mouse.getY() > y-20 then
                hoveredStatName = statName
            end
            intIndex = intIndex + 1
        end
        if intIndex < 5 then
            if currentCol < 2 then
                local x,y,w,h = definition.cell(currentCol+1)
                -- Calculate center position
                local labelWidth = w*3/4
                local centerX = x + (w - labelWidth)/2 + xOffset
                suit.layout:reset(centerX, y - 65, padding, padding)
                setFont(30)
                suit.Label("Unlock New Stat at lvl " .. Player.newStatLevelRequirement, {color = {normal = {fg = {1,1,1}}, hovered = {fg = {1,1,1}}, active = {fg = {1,1,1}}}, align = "center"}, suit.layout:row(labelWidth, cellHeight*4))
                if unlockNewStatQueued then
                    Player.newUpgradePrice = Player.newUpgradePrice * Player.upgradePriceMultScaling
                    setLevelUpShop(false) -- Set the level up shop with ball unlockedBallTypes
                    Player.choosingUpgrade = true -- Set the flag to indicate leveling up
                    unlockNewStatQueued = false
                end
                setFont(16)
            elseif i == math.max(rowCount,1) then
                y = y + 210 -- Add padding to the y position for the next row
                x = x + xOffset
                -- Calculate center position for full width label
                suit.layout:reset(10 + xOffset, y - 10, padding, padding)
                setFont(30)
                suit.Label("Unlock New Stat at lvl " .. Player.newStatLevelRequirement, {color = {normal = {fg = {1,1,1}}, hovered = {fg = {1,1,1}}, active = {fg = {1,1,1}}}, align = "center"}, suit.layout:row(w, cellHeight*4))
                if unlockNewStatQueued then
                    Player.newUpgradePrice = Player.newUpgradePrice * Player.upgradePriceMultScaling
                    setLevelUpShop(false) -- Set the level up shop with ball unlockedBallTypes
                    Player.choosingUpgrade = true -- Set the flag to indicate leveling up
                    unlockNewStatQueued = false
                end
            end
        end
        y = y + 210
        suit.layout:reset(10, y, 0, 0)
        suit.layout:row(statsWidth, 5) -- Add spacing for the separator
    end
end

local function getRarityColor(rarity)
    if rarity == "common" then
        return {0, 150/255, 1}
    elseif rarity == "uncommon" then
        return {1, 0, 200/255}
    elseif rarity == "rare" then
        return {1, 0, 0}
    elseif rarity == "legendary" then
        return {1, 200/255, 0}
    end
    return {1,1,1}

end

local function getRarityWindow(rarity, windowType)
    love.graphics.setColor(getRarityColor(rarity))
    if windowType == "small" then
        return uiSmallWindowImg
    elseif windowType == "mid" then
        return uiWindowImg
    else
        return uiBigWindowImg
    end
end

local statColor = {
    damage = {1,0,0},
    cooldown = {1, 218/255, 0},
    ammo = {72/255, 1, 0},
    fireRate = {0, 1, 149/255},
    amount = {0, 144/255, 1},
    range = {95/255, 0.1, 1},
    speed = {1, 0, 218/255}
}
unlockNewWeaponQueued = false
local currentBallShowHeight = 0
local function drawBallStats()
    if not (Player.levelingUp and not Player.choosingUpgrade) then
        return
    end 
    -----------------------------------
    -- Initialize position and layout --
    -----------------------------------
    local x, y = suit.layout:nextRow() -- Get the next row position
    local x, y = 10, 10 -- Starting position for the ball stats (horizontal from left)
    local w, h
    local padding = 100
    -- Initialize the layout with the starting position and padding
    suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)

    ----------------
    -- Draw Title --
    ----------------
    setFont(28)
    suit.layout:row(screenWidth - 20, 60)
    local x,y = suit.layout:nextRow()

    ----------------------------
    -- Prepare Ball List Data --
    ----------------------------
    
    local ballsToShow = {}
    for ballName, ballType in pairs(Balls.getUnlockedBallTypes()) do
        ballsToShow[ballName] = ballType
    end

    -----------------------
    -- Draw Ball Entries --
    -----------------------
    local startX = 460 -- Starting X position
    local currentX = startX -- Current X position for drawing
    local i = 0
    
    for ballName, ballType in pairs(ballsToShow) do
        i = i + 1
        if tableLength(ballsToShow) > 6 then
            if (i < (1 + currentBallShowHeight * 3)) or i > (6 + 3 * currentBallShowHeight) then goto continue
            else
                i = i - 3 * currentBallShowHeight
            end
        end
        -- Reset X position at the start of each row (every 3 balls)
        if (i-1) % 3 == 0 then
            currentX = startX
        end
        y = 475 + math.floor((i-1)/3) * 300 -- Move to next row every 3 balls
        suit.layout:reset(currentX, y, padding, padding)

        -- draw window
        love.graphics.draw(getRarityWindow(ballType.rarity, "mid"), currentX-25,y)    

        -- draw title label and title
        setFont(26)
        love.graphics.draw(uiLabelImg, currentX + statsWidth/2-uiLabelImg:getWidth()/2-10, y-25)
        setFont(getMaxFittingFontSize(ballType.name or "Unk", 30, uiLabelImg:getWidth()-20))
        drawTextCenteredWithScale(ballType.name or "Unk", currentX + statsWidth/2-uiLabelImg:getWidth()/2 + 3, y - 8, 1, uiLabelImg:getWidth()-20)

        -- type label
        setFont(20)
        local typeColor = {normal = {fg = {0.6,0.6,0.6,1}}}
        local labelY = y + uiLabelImg:getHeight()/2
        local bruhY = labelY
        -- suit.Label(ballType.type or "Unk type", {color = typeColor, align = "center"}, currentX + statsWidth/2-50-7, labelY, 100, 50)
        -- drawTextCenteredWithScale(ballType.type or "Unk type", currentX + statsWidth/2-50-7, labelY, 1, 100, {0.6,0.6,0.6,1})

        -- damageDealt label (top right, mirroring price)
        local damageDealt = ballType.damageDealt or 0
        local dmgText = tostring(formatNumber(damageDealt)) .. " dmg"
        setFont(25)
        local dmgOffsetX = -math.cos(math.rad(-2.5))*getTextSize(dmgText)/2
        local dmgTextWidth = love.graphics.getFont():getWidth(dmgText)

        -- Place at top right of the window, mirroring price
        local dmgX = currentX + statsWidth*1/4
        local dmgY = labelY + 13
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(dmgText, dmgX + 4 + dmgOffsetX, dmgY + 4,math.rad(-2.5))
        love.graphics.setColor(1,0.25,0.25,1)
        love.graphics.print(dmgText, dmgX + dmgOffsetX, dmgY, math.rad(-2.5))
        love.graphics.setColor(1,1,1,1)
        

        labelY = labelY + 20
        local statsX = currentX + 10
        if #Balls.getUnlockedBallTypes() > 1 then
        end
        local myLayout = {
            min_width = 410, -- Minimum width for the layout
            pos = {statsX, labelY + 40}, -- Starting position (x, y)
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
        statsX, labelY, w, h = definition.cell(1)
        suit.layout:reset(10, labelY, padding, padding) -- Set padding (10px horizontal and vertical)
        suit.layout:row(w, h)

        -- Draw upgrade buttons for each stat
        local intIndex = 1 -- keeps track of the current cell int id being checked
        -- Define the order of keys
        local statOrder = { "amount", "damage", "speed", "cooldown", "range", "fireRate", "ammo"} -- Order of stats to display

        -- makes sure amount is only called on things that use it
        local typeStats = {} -- Initialize the typeStats table
        if ballType.noAmount == false then
           typeStats = { amount = ballType.ballAmount } -- Start with amount
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
                statsX, labelY, w, h = definition.cell(intIndex)
                suit.layout:reset(statsX, labelY, padding, padding) -- Set padding (10px horizontal and vertical)
                setFont(20)

                local cellWidth = (430-10*rowCount)/rowCount
                
                -- draw value calculations
                suit.layout:padding(0, 0)
                -- Add permanent upgrades to the display value
                local permanentUpgradeValue = Player.permanentUpgrades[statName] or 0
                local bonusValue = getStatItemsBonus(statName, ballType) or 0
                local value = (Player.currentCore == "Cooldown Core" and statName == "cooldown") and 2 or statValue + bonusValue + permanentUpgradeValue
                if statName == "ammo" then
                    value = value - permanentUpgradeValue - bonusValue + bonusValue * ballType.ammoMult -- Adjust ammo value based on ammoMult
                end
                if (statName == "fireRate" or statName == "amount") and Player.currentCore == "Damage Core" then
                    value = 1
                end
                if statName == "damage" then
                    if Player.currentCore == "Damage Core" then
                        value = value * 5 -- Double damage for Damage Core
                    elseif Player.currentCore == "Phantom Core" and (ballType.type == "gun" or ballType.name == "Gun Turrets" or ballType.name == "Gun Ball")then
                        value = value / 2
                    end
                    if ballName == "Sniper" then
                        value = value * 10
                    end
                end
                --[[if statName == "amount" and ballType.noAmount == false and getStatItemsBonus("amount", ballType) > 0 then
                    value = value
                end]]
                if statName == "cooldown" then
                    value = math.max(0, value)
                end
                if Player.currentCore == "Madness Core" then
                    if statName == "damage" or statName == "cooldown" then
                        value = value * 0.5 -- Half damage and cooldown for Madness Core
                    else
                        value = value * 2 -- Double speed for Madness Core
                    end
                end
                -- draw stat value
                local scaleMult = 1
                if visualStatValues[ballType.name] then
                    if visualStatValues[ballType.name][statName] then
                        scaleMult = visualStatValues[ballType.name][statName].scale or 1
                    end
                end
                setFont(35 * scaleMult)
                local centeredLabelY = labelY - love.graphics.getFont():getHeight()/2 + 25
                if (Player.currentCore == "Phantom Core" and ballType.type == "gun" and statName == "damage") or (Player.currentCore == "Madness Core" and (statName == "damage" or statName == "cooldown")) then
                    drawTextCenteredWithScale(tostring(string.format("%.1f", value)), statsX, centeredLabelY-15, 1, cellWidth)
                else
                    drawTextCenteredWithScale(tostring(value), statsX, centeredLabelY-15, 1, cellWidth)
                end

                -- draw stat icon
                local iconX = statsX + cellWidth/2 - iconsImg[statName]:getWidth()*1.35/2 * 50/500 - 3
                love.graphics.draw(iconsImg[statName], iconX, labelY + 55,0,1.35 * 50/500,1.35 * 50/500)

                -- draw seperator
                if intIndex < rowCount then
                    love.graphics.setColor(0.4,0.4,0.4,1)
                    love.graphics.rectangle("fill", statsX + cellWidth, labelY, 1, 125)
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
                --local upgradeStatButton = dress:Button("", {color = invisButtonColor, id = buttonID}, statsX, labelY-10, cellWidth, 150)
                -- Right-click to remove all queued upgrades of this stat
                local canUpgrade = true
                -- Core-specific restrictions
                if statName == "cooldown" and Player.currentCore == "Cooldown Core" then
                    canUpgrade = false -- Cannot upgrade cooldown if using Cooldown Core
                end
                if ((statName == "fireRate" or statName == "amount") and Player.currentCore == "Damage Core") then
                    canUpgrade = false -- Cannot upgrade fireRate or amount if using Damage Core
                end
                -- Ammo restrictions
                if statName == "ammo" and (((ballType.stats.cooldown or 1000) + getStatItemsBonus("cooldown", ballType) + (Player.permanentUpgrades["cooldown"] or 0)) <= 0 and ballType.name ~= "Gun Turrets") then
                    canUpgrade = false -- Cannot upgrade ammo if cooldown is already at 0
                end
                local upgradeQueued = false
                if ballType.queuedUpgrades then
                    if ballType.queuedUpgrades[1] == statName then
                        upgradeQueued = true
                    end
                end
                --[[if ((upgradeStatButton.hit or (upgradeQueued and Player.money >= math.ceil(ballType.price))) and canUpgrade) and (usingMoneySystem or Player.levelingUp) then
                    if Player.money < math.ceil(ballType.price) then
                        -- does nothing
                    elseif statName == "cooldown" and getStat(ballName, "cooldown") <= 0 then
                        print("cannot upgrade cooldown any further")
                        playSoundEffect(upgradeSFX, 0.5, 0.95, false)
                    else
                        playSoundEffect(upgradeSFX, 0.5, 0.95, false)
                        if upgradeQueued then
                            for i, queuedUpgrade in ipairs(ballType.queuedUpgrades) do
                                if queuedUpgrade == statName then
                                    table.remove(ballType.queuedUpgrades, i)
                                    break
                                end
                            end
                        end
                        setFont(16)
                        print("Upgrading " .. ballType.name .. "'s " .. statName)
                        local stat = ballType.stats[statName] or 0-- Get the current stat value
                        if statName == "speed" then
                            ballType.stats.speed = ballType.stats.speed + 50 -- Example action
                            Balls.adjustSpeed(ballType.name) -- Adjust the speed of the ball
                        elseif statName == "amount" and not ballType.noAmount then
                            Balls.addBall(ballType.name, true) -- Add a new ball of the same type
                            ballType.ballAmount = ballType.ballAmount + 1
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
                        Player.pay(math.ceil(ballType.price)) -- Deduct the cost from the player's money
                        if usingMoneySystem then
                            ballType.price = ballType.price * 2 -- Increase the price of the ball
                        else
                            ballType.price = ballType.price + 1
                        end
                    end
                elseif upgradeStatButton.entered then
                    hoveredStatName = statName
                elseif upgradeStatButton.left then
                    hoveredStatName = nil
                end]]
                
                local upgradeCount = 0
                for _, queuedUpgrade in ipairs(ballType.queuedUpgrades) do
                    if queuedUpgrade == statName then
                        upgradeCount = upgradeCount + 1
                    end
                end
                setFont(30)
                if upgradeCount > 0 then
                    love.graphics.setColor(161/255, 231/255, 1, 1)
                    love.graphics.print((statName == "cooldown" and "-" or "+") .. upgradeCount, statsX + cellWidth/3*2 - 5, labelY - 5) -- Display queued upgrade count\
                end
                intIndex = intIndex + 1
                love.graphics.setColor(1,1,1,1)

                -- hover description
                local hoverButton = suit.Button("", {id = "bruhdmsavklsam" .. i .. ballName .. statName, color = totallyInvisButtonColor}, statsX, labelY, cellWidth - 20, 120)
                if hoverButton.hovered then
                    -- local mouseX, mouseY = love.mouse.getPosition()
                    setFont(35)
                    dress:Label(statName, {align = "center", color = {normal = {fg = statColor[statName]}}}, statsX - 90, labelY + 100, cellWidth + 180, 150)
                    dress:Label(statName, {align = "center", color = {normal = {fg = {0,0,0,1}}}}, statsX - 88, labelY + 98, cellWidth + 180, 150)
                    dress:Label(statName, {align = "center", color = {normal = {fg = {0,0,0,1}}}}, statsX - 92, labelY + 98, cellWidth + 180, 150)
                    dress:Label(statName, {align = "center", color = {normal = {fg = {0,0,0,1}}}}, statsX - 88, labelY + 102, cellWidth + 180, 150)
                    dress:Label(statName, {align = "center", color = {normal = {fg = {0,0,0,1}}}}, statsX - 92, labelY + 102, cellWidth + 180, 150)
                    -- drawTextCenteredWithScale(statName, mouseX, mouseY, 1, 300, {1,1,1,1})
                end
            end
        end
        suit.layout:row(statsWidth, 20) -- Add spacing for the separator
        
        -- price label
        local sizeMult
        if visualUpgradePriceValues[ballType.name] then
            sizeMult = visualUpgradePriceValues[ballType.name].scale 
        else
            sizeMult = 1
        end
        setFont(math.ceil(50) * sizeMult)
        local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(math.ceil(ballType.price)))/2
        labelY = bruhY - love.graphics.getFont():getHeight()/2 + 25
        love.graphics.setColor(0,0,0,1)
        love.graphics.print(formatNumber(math.ceil(ballType.price)) .. "$",currentX + statsWidth/2 + 104 +moneyOffsetX, labelY+4, math.rad(5))
        local moneyColor = Player.realMoney >= math.ceil(ballType.price) and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
        love.graphics.setColor(moneyColor)
        love.graphics.print(formatNumber(math.ceil(ballType.price)) .. "$",currentX + statsWidth/2 + 100 +moneyOffsetX, labelY, math.rad(5))
        love.graphics.setColor(1,1,1,1)

        -- upgrade button
        local buttonId = ballType.name .. "_upgradeButton"
        local upgradeStatButton = dress:Button("", {color = invisButtonColor, id = buttonId}, currentX + 10, y + 15, getRarityWindow("common"):getWidth() - 30, getRarityWindow("common"):getHeight()/2 - 30)
        if upgradeStatButton.hit then
            if Player.realMoney < math.ceil(ballType.price) then
                -- does nothing
            else
                playSoundEffect(upgradeSFX, 0.5, 0.95, false)
                Player.pay(math.ceil(ballType.price)) -- Deduct the cost from the player's money
                local totalStats = {}
                for statName, statValue in pairs(ballType.stats) do
                    totalStats[statName] = statValue
                end
                if ballType.type == "ball" then
                    totalStats["amount"] = ballType.ballAmount
                end
                ballType.price = ballType.price + tableLength(totalStats)
                for statName, statValue in pairs(totalStats) do
                    if statName == "cooldown" and getStat(ballName, "cooldown") <= 0 then
                        print("cannot upgrade cooldown any further")       
                    else
                        if upgradeQueued then
                            for i, queuedUpgrade in ipairs(ballType.queuedUpgrades) do
                                if queuedUpgrade == statName then
                                    table.remove(ballType.queuedUpgrades, i)
                                    break
                                end
                            end
                        end
                        setFont(16)
                        print("Upgrading " .. ballType.name .. "'s " .. statName)
                        local stat = ballType.stats[statName] or 0-- Get the current stat value
                        if statName == "speed" then
                            ballType.stats.speed = ballType.stats.speed + 50 -- Example action
                            Balls.adjustSpeed(ballType.name) -- Adjust the speed of the ball
                        elseif statName == "amount" and ballType.type == "ball" then
                            Balls.addBall(ballType.name, true) -- Add a new ball of the same type
                            ballType.ballAmount = ballType.ballAmount + 1
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
                    end
                end
            end
        end
        
        -- Move to next horizontal position
        currentX = currentX + statsWidth + 50 -- Move right for next ball (20px spacing)
        if tableLength(ballsToShow) > 6 then
            i = i + 3 * currentBallShowHeight
        end
        ::continue::
    end
    
    local numBalls = tableLength(Balls.getUnlockedBallTypes())
    local column = numBalls % 3 -- Get the current column (0, 1, or 2)
    
    -- If we're at the start of a new row, reset X position
    if column == 0 then
        currentX = startX
        y = y + 300 -- Move to next row
    end
    
    suit.layout:reset(currentX, y, padding, padding)
    love.graphics.draw(uiSmallWindowImg, currentX-25, y) -- Draw the background window image
    -- Button to unlock a new ball type
    setFont(30)
    local angle = angle or math.rad(1.5) -- Default angle if not provided
    love.graphics.setColor(1, 1, 1, 1)
    setFont(35)
    local levelRequirement = Player.level + (3 - ((Player.level - 1) % 3))

    drawTextCenteredWithScale("unlock new weapon at lvl " .. levelRequirement, currentX, y + 50, 1, uiSmallWindowImg:getWidth() - 40)
    if unlockNewWeaponQueued then
        --[[ Balls.NextBallPriceIncrease()
        setLevelUpShop(true) -- Set the level up shop with ball unlockedBallTypes
        Player.choosingUpgrade = true -- Set the flag to indicate leveling up
        -- unlockNewWeaponQueued = false]]
    end

    -- Add DOWN and UP buttons to the bottom of the area, side by side (no logic inside)
    if tableLength(ballsToShow) > 6 then
        local btnW, btnH = 120, 40
        -- Place buttons below the last row of balls
        local numRows = math.ceil(tableLength(ballsToShow) / 3)
        local btnY = screenHeight - btnH
        local btnX = startX + (screenWidth - startX - btnW)/2
        setFont(25)
        if currentBallShowHeight < math.ceil(tableLength(ballsToShow)/3) then
            if suit.Button("DOWN", {id="ballStatsDown"}, btnX, btnY, btnW, btnH).hit then
                currentBallShowHeight = math.min(currentBallShowHeight + 1, math.ceil(tableLength(ballsToShow)/3))
            end
        end
        btnX = btnX + btnW + 20
        if currentBallShowHeight > 0 then
            if suit.Button("UP", {id="ballStatsUp"}, btnX, btnY, btnW, btnH).hit then
                currentBallShowHeight = math.max(0, currentBallShowHeight - 1)
            end
        end
    end
end

function drawLevelUpShop()
    -- Initialize layout for the buttons
    love.graphics.setColor(1,1,1,1)
    local buttonWidth = (love.graphics.getWidth() - 300) / 3 - 60
    local buttonHeight = love.graphics.getHeight() - 500
    local buttonY = screenHeight/2 - buttonHeight/2 + 25
    -- print("level up shop opacity: " .. levelUpShopAlpha)
    local opacity = levelUpShopAlpha or 1
    --print("level up shop opacity: " .. opacity)
    local topText = levelUpShopType == "playerUpgrade" and "Choose a new Player Upgrade" or "Choose a new Weapon"
    setFont(60)
    love.graphics.print(topText, screenWidth/2 - getTextSize(topText)/2, buttonY - 175)

    -- Create a custom theme table that includes opacity
    local customTheme = {
        color = {
            normal = {bg = {0,0,0,0}, fg = {1,1,1,opacity}},
            hovered = {bg = {0.19,0.6,0.73,opacity*0.2}, fg = {1,1,1,opacity}},
            active = {bg = {1,0.6,0,opacity*0.2}, fg = {1,1,1,opacity}}
        }
    }

    for index, currentUpgrade in ipairs(displayedUpgrades) do
        -- Calculate button position
        local buttonX = 175 + (index - 1) * ((love.graphics.getWidth() - 300) / 3)

        -- Use suit to create a button with opacity
        suit.layout:reset(buttonX, buttonY, 10, 10)

        -- Check if mouse is over the button and brighten color if so
        local mx, my = love.mouse.getPosition()
        local isMouseOver = mx >= buttonX and mx <= buttonX + buttonWidth and my >= buttonY and my <= buttonY + buttonHeight

        love.graphics.setColor(0.5, 0.5, 0.5, opacity) -- Brighter background
        love.graphics.draw(getRarityWindow(currentUpgrade.rarity), buttonX - 10 * buttonWidth/getRarityWindow(currentUpgrade.rarity):getWidth(), buttonY, 0, buttonWidth/ getRarityWindow(currentUpgrade.rarity):getWidth(), buttonHeight/ getRarityWindow(currentUpgrade.rarity):getHeight()) -- Draw the background window image
        
        -- Draw labels with opacity
        love.graphics.setColor(1,1,1,opacity)
        

        suit.layout:row(buttonWidth-20,15)
        -- type specific logic
        setFont(35)
        dress:Label(currentUpgrade.name, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 55))
        setFont(30)
        dress:Label(currentUpgrade.type, {align = "center", color = {normal = {fg = {0.7,0.7,0.7,opacity}}}}, suit.layout:row(buttonWidth - 30, 45))
        setFont(24)
        dress:Label(currentUpgrade.description, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 150))
        suit.layout:row(buttonWidth - 20, 15)
        for statName, statValue in pairs(Balls.getBallList()[currentUpgrade.name].stats) do
            love.graphics.setColor(1,1,1,opacity)
            setFont(24)
            dress:Label(statName .. ": " .. statValue, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 30))
        end

        -- Register the invisible button with the custom theme
        local buttonID = "upgrade_" .. index
        suit.layout:reset(buttonX, buttonY, 10, 10)
        local buttonHit = suit.Button("", {id = buttonID, align = "center", color = customTheme.color}, suit.layout:col(buttonWidth, buttonHeight)).hit
        
        if buttonHit and opacity >= 0.995 then
            playSoundEffect(upgradeSFX, 0.5, 0.95, false)
            -- Button clicked: apply the effect and close the shop
            print("Clicked on upgrade: " .. currentUpgrade.name)
            currentUpgrade.effect() -- Apply the effect of the upgrade
            Player.onLevelUp()
            Player.choosingUpgrade = false
            if not usingMoneySystem then
                uiOffset.x = 0
                -- local uiRevealTween = tween.new(0.01, uiOffset, {x = 0}, tween.outExpo)
                -- addTweenToUpdate(uiRevealTween)
            end
        end
    end
    local x, y = suit.layout:nextRow()
    local x = screenWidth/2 - 150
    local w, h = 250, 75 -- Dimensions for the reroll button
    local buttonID = "reroll_button" -- Unique ID for the reroll button
    suit.layout:reset(x, y, 10, 10) -- Reset layout for the reroll button
    setFont(30)
    --[[if Player.rerolls > 0 then
        if suit.Button("Reroll", {id = buttonID, align = "center"}, suit.layout:row(w,h)).hit then
            Player.rerolls = Player.rerolls - 1
            local isBallShop = levelUpShopType == "ball"
            setLevelUpShop(isBallShop) -- Reroll the upgrades
        end
    end]]

end

local displayedItems = {}
local function getItemFullDescription(item)
    local description
    if type(item.description) == "function" then
        description = item.description()
    else
        description = item.description
    end
    if item.descriptionOverwrite then
        return description
    end
    local statsDescription = ""
    if item.stats then
        for statName, statValue in pairs(item.stats) do
            local displayValue = statValue
            statsDescription = statsDescription .. "<font=big><color=" .. statName ..">" .. ((statName == "cooldown" or statValue < 0) and "" or "+").. statValue .. " " .. statName .. "</color=" .. statName .. ">\n<color=white></font=big><font=default>"
        end
    end
    return statsDescription .. "\n" .. description
end

function setItemShop(forcedItems)
    clearFancyTexts()
    forcedItems = forcedItems or {}

    for i, v in ipairs(displayedItems) do -- when rolling past an item let it be roled into again
        Items.removeInvisibleItem(v.filteredName);
    end

    displayedItems = {}
    for i=1, 3 do
        local itemToDisplay = nil
        local itemIsGood = false
        if forcedItems[i] then
            itemToDisplay = forcedItems[i]
            if itemToDisplay then
                -- if itemToDisplay.onInShop then
                    -- itemToDisplay.onInShop(itemToDisplay)
                -- end

                getItemFullDescription(itemToDisplay)
                displayedItems[i] = itemToDisplay.new();
            else
                print("Error: No item found in setItemShop()")
            end

            goto continue
        end
        
        while not itemIsGood do
            itemToDisplay = Items.getRandomItem()
            itemIsGood = true
            if i > 1 then
                for j=1, i-1 do
                    if itemToDisplay.name == displayedItems[j].name then
                        itemIsGood = false
                        break
                    end
                end
            end
        end
        displayedItems[i] = itemToDisplay.new();

        ::continue::
        Items.addInvisibleItem(itemToDisplay.filteredName);
    end
end

local maxItems = 3

function setMaxItems(value)
    maxItems = value
end

function resetRerollPrice()
    if Player.currentCore == "Picky Core" then
        rerollPrice = 2
    elseif hasItem("Loaded Dice") then
        rerollPrice = 0
    else
        rerollPrice = 2
    end
end

local currentItemId = 0
local function drawItemShop()
    if Player.levelingUp and not Player.choosingUpgrade then
        setFont(60)
        for i=#displayedItems,1,-1 do

            -- set appropriate values
            local item = displayedItems[i]
            local scale = item.consumable and 0.8 or 1.0
            local windowW = uiBigWindowImg:getWidth() * 0.75 * scale
            local windowH = uiBigWindowImg:getHeight() * 0.65 * scale
            local itemX = 450 + (i-1) * (uiBigWindowImg:getWidth()*0.75 + 50)
            local itemY = 25
            -- Center the window at the same position as a normal item
            local centerX = itemX + uiBigWindowImg:getWidth()*0.75/2
            local centerY = itemY + uiBigWindowImg:getHeight()*0.65/2
            itemX = centerX - windowW/2
            itemY = centerY - windowH/2
            local upgradePrice = item.rarity == "common" and 8 or item.rarity == "uncommon" and 16 or item.rarity == "rare" and 24 or item.rarity == "legendary" and 30 or 0
            if item.consumable then
                upgradePrice = item.rarity == "common" and 4 or item.rarity == "uncommon" and 7 or item.rarity == "rare" and 10 or item.rarity == "legendary" and 13 or 0
            end
            if hasItem("Elon's Shmuck") then
                upgradePrice = 2
            end
            for i=1, itemCount("Coupon Collector") do
                upgradePrice = math.max(upgradePrice - 1, 0)
            end


            --description display when hovered
            local buyButton = dress:Button("", {id = "bruhdmsavklsam" .. i .. item.name, color = invisButtonColor}, itemX + 10, itemY + 12, windowW - 20, windowH - 24)
            if buyButton.hovered and item.image then
                love.graphics.draw(getRarityWindow(item.rarity or "common"), centerX - uiBigWindowImg:getWidth() * 0.65 * scale/2, itemY + windowH - 85, 0, 0.65 * scale, 0.55 * scale * (item.consumable and 1.25 or 1))
                local id = "fancyText" .. i .. item.name:gsub("%s+", "_")
                if fancyTexts[id] then
                    -- fancyTexts[id]:update()
                    fancyTexts[id]:draw()
                else
                    local text = getItemFullDescription(item) or ""
                    local fancyText = FancyText.new(text, centerX - uiBigWindowImg:getWidth() * 0.55 * scale/2, itemY + windowH, uiBigWindowImg:getWidth() * 0.55 * scale, 17, "center", item.descriptionPointers.default, item.descriptionPointers)
                    fancyTexts[id] = fancyText

                    fancyText:draw()
                end
                love.graphics.setColor(1, 1, 1, 1)

                -- draw item rarity
                local fontSize = item.rarity == "common" and 18 or item.rarity == "uncommon" and 20 or item.rarity == "rare" and 22 or item.rarity == "legendary" and 24 or 18
                setFont(fontSize)
                local rarityX = centerX - uiBigWindowImg:getWidth() * 0.55 * scale/2
                local rarityY = itemY + windowH - 60
                if item.consumable then
                    drawTextCenteredWithScale((item.rarity or "common"):gsub("^%l", string.upper), itemX, itemY + uiBigWindowImg:getHeight() * 0.8 - 10, 1, windowW, getRarityColor(item.rarity or "common"))
                    setFont(21)
                    drawTextCenteredWithScale("consumable", itemX, itemY + uiBigWindowImg:getHeight() * 0.8 + 15, 1, windowW, {0.85,0.85,0.85,1})
                else
                    drawTextCenteredWithScale((item.rarity or "common"):gsub("^%l", string.upper), itemX, itemY + uiBigWindowImg:getHeight() - 20, 1, windowW, getRarityColor(item.rarity or "common"))
                end

            end

            -- draw main window
            local color = {1, 1, 1, 1}
            love.graphics.setColor(color)
            love.graphics.draw(getRarityWindow(item.rarity or "common"), itemX, itemY, 0, 0.75 * scale, 0.65 * scale)

            -- draw item name
            setFont(27)
            drawTextCenteredWithScale(item.name or "Unknown", itemX + 10 * scale, itemY + 30 * scale, scale, windowW - 20 * scale, color)
            
            if item.image then
                love.graphics.setColor(1,1,1,1)
                local imgScale = scale * 0.75
                love.graphics.draw(item.image,centerX - (item.image:getWidth()*imgScale)/2, itemY + 130 * imgScale,0,imgScale,imgScale)
            else
                --[[local getValue = function() return longTermInvestment.value end
                local pointers = {
                    default = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 18),
                    big = love.graphics.newFont("assets/Fonts/KenneyFuture.ttf", 23),
                    bold = love.graphics.newFont("assets/Fonts/KenneyFutureBold.ttf", 25),
                    longTermValue = getValue
                }
                if item.descriptionPointers then
                    for valueName, functionPointer in pairs(item.descriptionPointers) do
                        pointers[valueName] = functionPointer
                    end
                end]]
                local id = "fancyText" .. i .. item.name:gsub("%s+", "_")
                if fancyTexts[id] then
                    -- fancyTexts[id]:update()
                    fancyTexts[id]:draw()
                else
                    local text = getItemFullDescription(item) or ""
                    local fancyText = FancyText.new(text, itemX + 25 * scale, itemY + 110 * scale, windowW - 50 * scale, 20, "center", item.descriptionPointers.default, item.descriptionPointers)
                    fancyTexts[id] = fancyText

                    print("fancytext drawing : " .. id)

                    fancyText:draw()
                end
            end

            if buyButton.hit then
                print("button working")
                -- if (#Player.items < maxItems or item.consumable) and Player.money >= upgradePrice then
                if Player.realMoney >= upgradePrice then
                    Player.pay(upgradePrice)
                    playSoundEffect(upgradeSFX, 0.5, 0.95)
                    table.remove(displayedItems, i)

                    item:buy();
                    if item.consumable and hasItem("Sommelier") then
                        item:buy(); -- buy again
                    end

                    if not item.consumable then
                        table.insert(Player.items, item);
                        Player.items[#Player.items].id = item.name .. tostring(currentItemId);
                        currentItemId = currentItemId + 1;
                        -- Keep Player.items grouped so identical items are adjacent
                        if reorderPlayerItems then reorderPlayerItems() end
                    end
                    if item.stats.amount then
                        Balls.amountIncrease(item.stats.amount)
                    end
                    for _, weaponType in pairs(Balls.getUnlockedBallTypes()) do
                        if weaponType.type == "ball" then
                            Balls.adjustSpeed(weaponType.name) -- Adjust the speed of the ball
                        end
                    end
                    
                    local itemList = item.rarity == "common" and commonItems or item.rarity == "uncommon" and uncommonItems or item.rarity == "rare" and rareItems or item.rarity == "legendary" and legendaryItems or {}
                    local indexToRemove = nil
                    for index, itemName in ipairs(itemList) do
                        if itemName == item.name then
                            indexToRemove = index
                            break
                        end
                    end
                    if indexToRemove then
                        table.remove(itemList, indexToRemove)
                    end
                end
            end
            local moneyXoffset = item.consumable and -65 or 0
            local moneyYoffset = item.consumable and -25 or 0
            printMoney(upgradePrice, itemX + uiBigWindowImg:getWidth() * 0.75 - 40 - getTextSize(upgradePrice .. "$")/2 + moneyXoffset, itemY + uiBigWindowImg:getHeight() * 0.65/2 - 85 + moneyYoffset, math.rad(4), Player.realMoney >= upgradePrice, 50)

            i = i + 1
        end
        love.graphics.draw(uiLabelImg, screenWidth - 275, 50 + uiBigWindowImg:getHeight() * 0.65/2 - 60) -- Draw the title background image
        setFont(30)
        local actualRerollPrice = Player.currentCore == "Picky Core" and 1 or rerollPrice
        if hasItem("Elon's Shmuck") then
            actualRerollPrice = 2
        end
        if suit.Button("Reroll", {id = "reroll_items", color = invisButtonColor}, screenWidth - 260, 50 + uiBigWindowImg:getHeight() * 0.65/2 - 57, uiLabelImg:getWidth() - 30, uiLabelImg:getHeight() - 6).hit then
            if Player.realMoney >= actualRerollPrice then
                Player.pay(actualRerollPrice)
                -- playSoundEffect(upgradeSFX, 0.5, 0.95)
                setItemShop()
                if Player.currentCore ~= "Picky Core" then
                    rerollPrice = rerollPrice + 1
                end
                
            end
        end
        printMoney(actualRerollPrice, screenWidth - 40 - getTextSize(actualRerollPrice .. "$")/2, 30 + uiBigWindowImg:getHeight() * 0.65/2 - 60, math.rad(4), Player.realMoney >= actualRerollPrice, 40)
    end
end

function deletePlayerItemById(itemId)
    for i, item in ipairs(Player.items) do
        if item.id == itemId then
            table.remove(Player.items, i)
            return
        end
    end
    error("Warning: Tried to delete player item with id " .. tostring(itemId) .. " but it was not found.")
end

hoveringPlayerItem = nil
local function drawPlayerItems()
    if Player.levelingUp and not Player.choosingUpgrade then

        -- print title
        love.graphics.setColor(1,1,1,1)
        love.graphics.print("Items", 200 - getTextSize("Items")/2, 400)

        -- Aggregate duplicates so we only draw each unique item once
        local uniqueMap = {}
        local uniqueOrder = {}
        for _, item in ipairs(Player.items) do
            local key = item.filteredName or item.templateFilteredName or item.name or tostring(item)
            if not uniqueMap[key] then
                uniqueMap[key] = {sample = item, count = 1, ids = {item.id}}
                table.insert(uniqueOrder, key)
            else
                uniqueMap[key].count = uniqueMap[key].count + 1
                table.insert(uniqueMap[key].ids, item.id)
            end
        end

        local hoveredItem = nil
        local hoveredItemIndex = nil

        -- Draw each unique item once
        for index, key in ipairs(uniqueOrder) do
            local entry = uniqueMap[key]
            local item = entry.sample

            -- Keep original row-based positioning, just scaled
            local itemWidth = 140
            local itemHeight = 125
            local itemX = ((index - 1) % 3) * itemWidth
            local startingY = screenHeight/2 - 85 -- Don't scale the starting Y
            local itemY = startingY + math.floor((index - 1)/3) * itemHeight

            if not item.image then
                item.image = defaultItemImage
            end
            if item.image then
                local imgScaleMult = 1
                local representativeName = entry.sample.filteredName or entry.sample.templateFilteredName or entry.sample.name
                if representativeName and visualItemValues[representativeName] then
                    imgScaleMult = visualItemValues[representativeName].scale
                else
                    -- fallback: try using the sample item's name
                    if item.name and visualItemValues[item.name] then
                        imgScaleMult = visualItemValues[item.name].scale
                    end
                end
                local xOffset, yOffset = -(imgScaleMult-1) * itemWidth * 0.5, -(imgScaleMult-1) * itemHeight * 0.5
                love.graphics.draw(item.image, itemX + xOffset, itemY + yOffset, 0, 0.5 * imgScaleMult, 0.5 * imgScaleMult)
            end

            -- Draw counter badge if owning more than one
            if entry.count and entry.count > 1 then
                local badgeX = itemX + itemWidth * 3/4
                local badgeY = itemY + 30
                local badgeRadius = 14
                
                setFont(28)
                local countText = "x"..tostring(entry.count)
                local tw = love.graphics.getFont():getWidth(countText)
                local th = love.graphics.getFont():getHeight()
                love.graphics.setColor(0, 0, 0, 1)
                love.graphics.print(countText, badgeX - tw/2 - 1, badgeY - th/2 - 1)
                love.graphics.print(countText, badgeX - tw/2 + 1, badgeY - th/2 - 1)
                love.graphics.print(countText, badgeX - tw/2 - 1, badgeY - th/2 + 1)
                love.graphics.print(countText, badgeX - tw/2 + 1, badgeY - th/2 + 1)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(countText, badgeX - tw/2, badgeY - th/2)
            end

            -- Check if mouse is hovering over this (unique) item
            local mouseX, mouseY = love.mouse.getPosition()
            if mouseX >= itemX and mouseX <= itemX + itemWidth and
               mouseY >= itemY and mouseY <= itemY + itemHeight then
                hoveredItem = item
                hoveredItemIndex = index
            end
        end

        -- Show description for hovered unique item
        if hoveredItem then
            hoveringPlayerItem = hoveredItem.id or hoveredItem.name
            local item = hoveredItem
            local index = hoveredItemIndex
            local itemWidth = 140
            local itemHeight = 125
            local itemX = ((index - 1) % 3) * itemWidth
            local startingY = screenHeight/2 - 85 -- Don't scale the starting Y
            local itemY = startingY + math.floor((index - 1)/3) * itemHeight

            itemX = itemX + itemWidth
            -- Show description when hovered
            love.graphics.draw(getRarityWindow(item.rarity or "common", "mid"), itemX, itemY, 0, 0.5, 0.75)
            setFont(18)
            drawTextCenteredWithScale(item.name or "Unknown", itemX + 12, itemY + 15, 1, (uiBigWindowImg:getWidth() - 20)/2, {1,1,1,1})

            local id = "fancyText, player.items" .. index .. item.name:gsub("%s+", "_") .. (item.id or "")
            if fancyTexts[id] then
                fancyTexts[id]:draw()
            else
                local text = getItemFullDescription(item) or ""
                local fancyText = FancyText.new(text, itemX + 15, itemY + 70, (uiBigWindowImg:getWidth() - 25)/2, 12, "center", item.descriptionPointers.default, item.descriptionPointers)
                fancyTexts[id] = fancyText

                fancyText:draw()
            end

            -- draw sell text
            local id = "fancyText, player.items, sell button" .. index .. item.name:gsub("%s+", "_") .. (item.id or "")
            local sellValue = item.rarity == "common" and 4 or item.rarity == "uncommon" and 8 or item.rarity == "rare" and 12 or item.rarity == "legendary" and 16 or 0
            if fancyTexts[id] then
                fancyTexts[id]:draw()
            else
                local text = "Right click to sell for <color=money><font=big>" .. sellValue .. "$"
                local fancyText = FancyText.new(text, itemX + 20, itemY + itemHeight + 70, (uiBigWindowImg:getWidth() - 25)/2, 13, "center", item.descriptionPointers.default, item.descriptionPointers)
                fancyTexts[id] = fancyText

                fancyText:draw()
            end
        else
            hoveringPlayerItem = nil
        end
    else
        hoveringPlayerItem = nil
    end
    
end

playerMoneyBoost = {alpha = 0}
local function drawPlayerMoney()
    -- render money
    local opacity = 1
    if not Player.levelingUp then
        opacity = playerMoneyBoost.alpha
    end
    local x, y, w, h = 965, 930, 210, 30
    local fontSize = 80 * visualMoneyValues.scale
    setFont(fontSize)
    x,y = statsWidth/2 - getTextSize(formatNumber(Player.getMoney()))/2 - 100, 175 - love.graphics.getFont():getHeight()/2 -- Adjust position for better alignment
    love.graphics.setColor(0,0,0,opacity)
    love.graphics.print(formatNumber(Player.getMoney()) .. "$",x + 104, y +5, math.rad(1.5))
    local moneyColor = {14/255, 202/255, 92/255,opacity}
    love.graphics.setColor(moneyColor)
    love.graphics.print(formatNumber(Player.getMoney()) .. "$",x + 100, y + 1, math.rad(1.5))
end

local function drawFinishUpgradingButton()
    if Player.levelingUp and not Player.choosingUpgrade then
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(defaultScreenImg, 0, 0, 0)
        --[[
        local buttonW, buttonH = 400, 120
        local buttonX = screenWidth/2 - buttonW/2
        local buttonY = screenHeight - buttonH - 10
        setFont(30)
        love.graphics.setColor(0,0,0,0.6)
        love.graphics.rectangle("fill", screenWidth/2 - buttonW/2, screenHeight - buttonH + 10, buttonW, buttonH)
        love.graphics.setColor(1,1,1,1)]]
        -- drawTextCenteredWithScale("Press [SPACE] to Finish Upgrading", screenWidth/2 - buttonW/2, screenHeight - buttonH + 35, 1, buttonW, {1,1,1,1})
        --[[if suit.Button("Finish Upgrading", {id="finishUpgrading", valign = "top"}, buttonX, buttonY, buttonW, buttonH).hit then
            finishUpgrading()
        end]]
    end
end

function upgradesUI.draw()

    drawCooldownVFXs()
    drawPlayerStats() -- Draw the player stats table
    drawPlayerMoney()
    drawBallStats() -- Draw the ball stats table
    drawItemShop()
    drawPlayerItems()
    drawFinishUpgradingButton()

    -- Draw stat hover label if hovering a stat
    if hoveredStatName and Player.levelingUp then
        local mx, my = love.mouse.getPosition()
        setFont(22)
        local tw = love.graphics.getFont():getWidth(hoveredStatName)
        local th = love.graphics.getFont():getHeight()
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill", mx-80 - tw, my-8, tw+86, th+65, 6, 6)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(hoveredStatName, mx - tw - 40, my-4)
    end
    love.graphics.setColor(1,1,1,1)
end

function upgradesUI.update(dt)
    updateCooldownTimers(dt)
end

return upgradesUI
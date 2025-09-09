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

-- items list

local items = {
    ["Running Shoes"] = {
        rarity = "common",
        stats = {speed = 2},
        description = "+2 speed",
    },
    ["Balls To The Wall"] = {
        rarity = "common",
        stats = {speed = 1, amount = 1, damage = 1},
        description = "balls gain +1 speed, amount and damage",
        statCondition = function() end
    },
    ["Kitchen Knife"] = {
        rarity = "common",
        stats = {damage = 2},
        description = "+2 damage",
    },
    ["Duct Tape"] = {
        rarity = "common",
        stats = {cooldown = -2},
        description = "-2 cooldown",
    },
    ["2 for 1 meal ticket"] = {
        rarity = "common",
        stats = {amount = 2},
        description = "+2 amount",
    },
    ["Fake pregnancy belly"] = {
        stats = {range = 2},
        description = "+2 range",
        rarity = "common"
    },
    ["Extended Magazine"] = {
        stats = {ammo = 2},
        description = "+2 ammo",
        rarity = "common"
    },
    ["Fast Hand"] = {
        stats = {fireRate = 2},
        description = "+2 fireRate",
        rarity = "common"
    },
    ["Financial Plan"] = {
        stats = {},
        description = "+2$ per level",
        rarity = "common"
    },
    ["Ol' reliable"] = {
        stats = {},
        description = "+1 to every stat of your starting item",
        rarity = "common"
    },
    ["Ballbuster"] = {
        stats = {damage = 1, speed = 1, amount = 1},
        description = "Ball weapons gain +1 damage, speed and amount",
        rarity = "common"
    },
    ["Sharpshooter"] = {
        stats = {damage = 1, fireRate = 1, ammo = 1},
        description = "Increases damage, fire rate and ammo of gun weapons by 1",
        rarity = "common"
    },
    ["Handy Wrench"] = {
        stats = {},
        description = "When you buy this, all your weapons get an upgrade to a random one of their stats",
        rarity = "uncommon",
        onBuy = function() end
    },
    ["Satanic Necklace"] = {
        stats = {damage = 5, amount = -1, fireRate = -1},
        description = "+5 damage, -1 amount, -1 fireRate",
        rarity = "uncommon"
    },
    ["Ballin'"] = {
        stats = {damage = 2, speed = 2, amount = 2},
        description = "Ball weapons gain +2 damage, speed and amount",
        rarity = "uncommon"
    },
    ["Spray and pray"] = {
        stats = {fireRate = 2, ammo = 2, damage = 2},
        description = "Increases fire rate and ammo of all weapons by 2",
        rarity = "uncommon"
    },
    ["Degenerate Gambling"] = {
        stats = {},
        description = "-1$ per level, 20% chance to gain 20$ on level up",
        rarity = "uncommon"
    },
    ["Nerdy Glasses"] = {
        stats = {damage = -1, speed = -1, cooldown = 1, size = -1, amount = -1, range = -1, fireRate = -1, ammo = -1},
        description = "+5$ per Level, -1 to every stat (+1 to cooldown)",
        rarity = "uncommon",
    },
    ["Bouncy walls"] = {
        stats = {},
        description = "Balls gain a temporary boost of speed after bouncing off walls",
        rarity = "uncommon"
    },
    ["Four Leafed Clover"] = {
        stats = {},
        description = "+1$ per level, you are twice as likely to find uncommon or rare weapons or items in the shop",
        rarity = "uncommon"
    },
    ["Swiss Army Knife"] = {
        stats = {damage = 1, fireRate = 1, speed = 1, cooldown = 1, size = 1, amount = 1, range = 1, ammo = 1},
        description = "Increases all stats of your weapons by 1",
        rarity = "uncommon"
    },
    ["Homing Bullets"] = {
        stats = {fireRate = 1, ammo = 1, cooldown = -1},
        description = "Bullets will home in on the nearest brick",
        rarity = "uncommon"
    },
    ["Paddle Defense System"] = {
        stats = {},
        description = "When balls bounce on the paddle, shoot a bullet that deals damage equal to that ball's damage",
        rarity = "uncommon"
    },
    ["Trinity Force"] = {
        stats = {speed = 3, damage = 3, amount = 3},
        description = "Increases the speed, amount and damage of ball weapons by 3",
        rarity = "rare"
    },
    ["Gunslinger"] = {
        stats = {damage = 3, fireRate = 3, ammo = 3},
        description = "Increases damage, fire rate and ammo of gun weapons by 3",
        rarity = "rare"
    },
    ["Electromagnetic alignment"] = {
        stats = {},
        description = "balls gain a magnetic attraction towards bricks. (doesn't affect Magnetic Ball)",
        rarity = "rare"
    },
    ["Sudden Mitosis"] = {
        stats = {},
        description = "50% chance for balls to spawn a small copy of themselves that lasts for 6 seconds on paddleBounce",
        rarity = "rare"
    },
    ["Jack Of All Trades"] = {
        stats = {speed = 2, cooldown = -2, size = 2, amount = 2, range = 2, fireRate = 2, ammo = 2},
        description = "Increases all stats of your weapons by 2 (except damage), but decreases cooldown by 2",
        rarity = "rare"
    },
    ["Split Shooter"] = {
        stats = {},
        description = "Bullets have a 50% chance to split into 2 after being shot",
        rarity = "rare"
    },
    ["Blind Violence"] = {
        stats = {damage = 10, speed = -2, amount = -2, cooldown = 2, range = -2, fireRate = -2, ammo = -2},
        description = "Damage + 10, but all other stats -2 (cooldown + 2)",
        rarity = "rare"
    },
    ["Omnipotence"] = {
        stats = {speed = 3, damage = 3, cooldown = -3, size = 3, amount = 3, range = 3, fireRate = 3, ammo = 3},
        description = "Increases all stats of your weapons by 3",
        rarity = "legendary"
    },
    ["Crazy Fingers"] = {
        stats = {},
        description = "fireRate items shoot Twice as fast but are a lot less accurate",
        rarity = "legendary"
    },
    ["Bouncing Castle"] = {
        stats = {},
        description = "Whenever a ball bounces it gains a temporary speed boost",
        rarity = "legendary"
    }

}

function getItem(itemName) 
    return items[itemName]
end

function getStatItemsBonus(statName)
    local totalBonus = 0
    for itemName, item in pairs(items) do
        if Player:hasItem(itemName) and item.stats[statName] then
            totalBonus = totalBonus + item.stats[statName]
        end
    end
    return totalBonus
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

uiOffset = {x = 0, y = 0}
local drawPlayerStatsHeight = 200 -- Height of the player stats section
local function drawPlayerStats()
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

    -- render money
    local x, y, w, h = definition.cell(2)
    local fontSize = 80 * (moneyScale.scale or 1)
    setFont(fontSize)
    love.graphics.setColor(1,1,1,1)
    x,y = statsWidth/2 - getTextSize(formatNumber(Player.money))/2 - 100 + xOffset, 175 - love.graphics.getFont():getHeight()/2 -- Adjust position for better alignment
    local moneyOffsetX = 0---math.cos(math.rad(5))*getTextSize(formatNumber(Player.money))/2
    love.graphics.setColor(0,0,0,1)
    love.graphics.print(formatNumber(Player.money) .. "$",x + 104 +moneyOffsetX, y +5, math.rad(1.5))
    local moneyColor = {14/255, 202/255, 92/255,1}
    love.graphics.setColor(moneyColor)
    love.graphics.print(formatNumber(Player.money) .. "$",x + 100 + moneyOffsetX, y + 1, math.rad(1.5))

    -- render interest if player has not finished leveling up
    local interestValue = math.floor(math.min(Player.money, Player.currentCore == "Economy Core" and 50 or 25)/5) + 5
    if Player.levelingUp and interestValue > 0 then
        setFont(45)
        love.graphics.setColor(moneyColor)
        x, y = x + 90, y - 45
        love.graphics.print("+" .. formatNumber(interestValue) .. "$",x + 100 + moneyOffsetX, y + 1, math.rad(1.5))
    end



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
        love.graphics.print(coreText, statsWidth/2 - tw/2 + xOffset, 40 - th/2)
        love.graphics.setColor(1, 1, 1, 1)
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

local levelUpShopType = "weapon"
local displayedUpgrades = {} -- This should be an array, not a table with string keys
local tweenSpeed = 2 -- Adjust this to control fade in speed

function setLevelUpShop(isForBall, isForPerks)
    levelUpShopAlpha = 0
    isForPerks = isForPerks or false -- Default to false if not provided
    isForSpells = isForSpells or false
    if isForPerks then isForBall = false end -- If perks are requested, set isForBall to false
    shouldTweenAlpha = true
    displayedUpgrades = {} -- Clear the displayed upgrades
    if isForBall then
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
        
        for name, ballType in pairs(Balls.getBallList()) do
            if (not unlockedBallNames[name]) then
                local weight = 0
                local ballList = Balls.getBallList()
                
                -- Calculate weight based on rarity and unlock count
                if ballList[ballType.name].rarity == "common" then
                    if unlockedCount <= 2 then
                        weight = 7  -- High weight for commons early
                    else
                        weight = 5
                    end
                elseif ballList[ballType.name].rarity == "uncommon" then
                    if unlockedCount == 1 then
                        weight = 2
                    else
                        weight = 4
                    end
                elseif ballList[ballType.name].rarity == "rare" then
                    if unlockedCount == 1 then
                        weight = 0   -- No rare balls with just 1 unlock
                    elseif unlockedCount == 2 then
                        weight = 1
                    else
                        weight = 3
                    end
                elseif ballList[ballType.name].rarity == "legendary" then
                    if unlockedCount < 3 then
                        weight = 0   -- No legendaries until 3 unlocks
                    else
                        weight = 6
                    end
                else
                    weight = 7  -- Default weight for unspecified rarity
                end

                if ballList[ballType.name].canBuy then
                    if not ballList[ballType.name].canBuy() then
                        weight = 0 -- Exclude spells from ball unlocks
                    end
                end
                -- Only add balls with weight > 0
                if weight > 0 then
                    for i=1, weight do
                        table.insert(weightedBalls, {
                            ball = ballType,
                            weight = weight
                        })
                    end
                end
            end
        end

        for i=1, 3 do
            local thisBallType
            local doAgain = true
            while doAgain do
                local randomIndex = math.random(1, #weightedBalls)
                thisBallType = weightedBalls[randomIndex].ball
                doAgain = false

                if (thisBallType.rarity == "rare" or thisBallType.rarity == "legendary") and #Balls.getUnlockedBallTypes() < 2 then
                    doAgain = true
                end

                if thisBallType.canBuy then
                    if not thisBallType.canBuy() then
                        doAgain = true
                    end
                end

                for _, displayedUpgrade in ipairs(displayedUpgrades) do
                    if displayedUpgrade.name == thisBallType.name then
                        doAgain = true
                        break
                    end
                end
            end
            table.insert(displayedUpgrades, {
                name = thisBallType.name,
                description = thisBallType.description,
                effect = function()
                    print("will add ball: " .. thisBallType.name)
                    Balls.addBall(thisBallType.name)
                end
            })
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
                if not Player.bonuses[statName] then
                -- Only add if it's allowed for current core and not already in list
                if not ((Player.currentCore == "Damage Core") and (statName == "fireRate" or statName == "amount")) 
                and not (Player.currentCore == "Cooldown Core" and statName == "cooldown") then
                    -- Check if already exists
                    local alreadyExists = false
                    for _, bonus in ipairs(advantagiousBonuses) do
                        if bonus == statName then
                            alreadyExists = true
                            break
                        end
                    end
                    -- Add if new
                    if not alreadyExists then
                        table.insert(advantagiousBonuses, statName)
                    end
                end
            end
            end
            if (not item.noAmount) and Player.bonuses.amount == nil then
                table.insert(advantagiousBonuses, "amount")
            end
        end
        levelUpShopType = "playerUpgrade"
        local availableBonuses = {}
        for bonusName, bonus in pairs(Player.bonusesList) do
            if (not Player.bonuses[bonusName]) and not ((Player.currentCore == "Damage Core") and (bonusName == "fireRate" or bonusName == "amount")) and not (Player.currentCore == "Cooldown Core" and bonusName == "cooldown") then
                table.insert(availableBonuses, bonusName)
                print("available bonusName = " .. bonusName)
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
                    local iterations = 0
                    while bruh do 
                        iterations = iterations + 1
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
                        if iterations >= 100 then
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
                    local iterations = 0
                    while bruh do
                        iterations = iterations + 1
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
                        if iterations >= 100 then
                            bruh = false
                        end
                    end
                    availableBonuses[index] = nil -- Remove this bonus from the availableBonuses list
                    print("false")
                end

                print("Current bonus: " .. tostring(currentBonus or "nil"))
                print("index: " .. tostring(index))
                if currentBonus then
                    table.insert(displayedUpgrades, {
                        name = Player.bonusesList[currentBonus].name,
                        description = Player.bonusesList[currentBonus].description,
                        effect = function()
                            print("Adding bonus: " .. currentBonus)
                            Player.addBonus(currentBonus) -- Add the new bonus to the player
                            if usingMoneySystem then
                                Player.bonusUpgrades[currentBonus]() -- Call the upgrade function
                            end
                        end
                    })
                end
                
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
            local moneyColor = Player.money >= Player.bonusPrice[bonusName] and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
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
            -- Check if the player has enough money to upgrade
            local upgradeQueued = false
            if Player.queuedUpgrades then
                if Player.queuedUpgrades[1] == bonusName then
                    upgradeQueued = true
                end
            end
            if upgradeStatButton.hit or (upgradeQueued and Player.money >= math.ceil(Player.bonusPrice[bonusName])) and (usingMoneySystem or Player.levelingUp) then
                if Player.money < math.ceil(Player.bonusPrice[bonusName]) then
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

unlockNewWeaponQueued = false
local function drawBallStats() 
    local xOffset = uiOffset.x
    local x, y = suit.layout:nextRow() -- Get the next row position
    local x, y = screenWidth - statsWidth + 10 + xOffset, 10 -- Starting position for the ball stats
    local w, h
    -- Initialize the layout with the starting position and padding
    suit.layout:reset(x, y, 10, 10) -- Set padding (10px horizontal and vertical)

    --draw Title
    setFont(28) -- Set font for the title
    love.graphics.draw(uiLabelImg, screenWidth-statsWidth/2-140 * 1.1 + xOffset, -12,0,1.1,1.1)
    suit.Label("Ball Types", {align = "center"}, screenWidth-statsWidth/2-140*1.1 + xOffset, 5, 280 * 1.1, 30)
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

        suit.layout:reset(x + xOffset, y, 10, 10)

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
        --suit.Label(ballType.type or "Unk type", {color = typeColor, align = "center"}, x + statsWidth/2-50-7, y, 100, 50)

        -- price label
        if Player.currentCore ~= "Farm Core" then
            setFont(50)
            local moneyOffsetX = -math.cos(math.rad(5))*getTextSize(formatNumber(math.ceil(ballType.price)))/2
            love.graphics.setColor(0,0,0,1)
            love.graphics.print(formatNumber(math.ceil(ballType.price)) .. "$",x + statsWidth/2 + 104 +moneyOffsetX, y+4, math.rad(5))
            local moneyColor = Player.money >= math.ceil(ballType.price) and {14/255, 202/255, 92/255,1} or {164/255, 14/255, 14/255,1}
            love.graphics.setColor(moneyColor)
            love.graphics.print(formatNumber(math.ceil(ballType.price)) .. "$",x + statsWidth/2 + 100 +moneyOffsetX, y, math.rad(5))
            love.graphics.setColor(1,1,1,1)
        end

        -- damageDealt label (top right, mirroring price)
        local damageDealt = ballType.damageDealt or 0
        local dmgText = tostring(formatNumber(damageDealt)) .. " dmg"
        setFont(30)
        local dmgOffsetX = -math.cos(math.rad(-2.5))*getTextSize(dmgText)/2
        local dmgTextWidth = love.graphics.getFont():getWidth(dmgText)

        -- Place at top right of the window, mirroring price
        local dmgX = screenWidth - statsWidth*3/4 + xOffset
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
                -- Add permanent upgrades to the display value
                local permanentUpgradeValue = Player.permanentUpgrades[statName] or 0
                local bonusValue = Player.bonuses[statName] or 0
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
                    elseif Player.currentCore == "Phantom Core" and (ballType.type == "gun" or ballType.name == "Turret Generator" or ballType.name == "Gun Ball")then
                        value = value / 2
                    end
                    if ballName == "Sniper" then
                        value = value * 10
                    end
                end
                if statName == "amount" and ballType.noAmount == false then
                    value = value - (Player.bonuses.amount or 0)
                end
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
                if (Player.currentCore == "Phantom Core" and ballType.type == "gun" and statName == "damage") or (Player.currentCore == "Madness Core" and (statName == "damage" or statName == "cooldown")) then
                    suit.Label(tostring(string.format("%.1f", value)), {align = "center"}, x, y-25, cellWidth, 100)
                else
                    suit.Label(tostring(value), {align = "center"}, x, y-25, cellWidth, 100)
                end

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
                if statName == "ammo" and (((ballType.stats.cooldown or 1000) + (Player.bonuses["cooldown"] or 0) + (Player.permanentUpgrades["cooldown"] or 0)) <= 0 and ballType.name ~= "Turret Generator") then
                    canUpgrade = false -- Cannot upgrade ammo if cooldown is already at 0
                end
                local upgradeQueued = false
                if ballType.queuedUpgrades then
                    if ballType.queuedUpgrades[1] == statName then
                        upgradeQueued = true
                    end
                end
                if ((upgradeStatButton.hit or (upgradeQueued and Player.money >= math.ceil(ballType.price))) and canUpgrade and Player.currentCore ~= "Farm Core") and (usingMoneySystem or Player.levelingUp) then
                    if Player.money < math.ceil(ballType.price) then
                        if usingMoneySystem then
                            local cooldownQueued = 0
                            for _, queuedUpgrade in ipairs(ballType.queuedUpgrades) do
                                if queuedUpgrade == "cooldown" then
                                    cooldownQueued = cooldownQueued + 1
                                end
                            end
                        end
                        if not (statName == "cooldown" and getStat(ballName, "cooldown") - cooldownQueued <= 0) then
                            -- queue upgrade
                            if (not (statName == "cooldown" and getStat(ballName, "cooldown") <= 0)) and #ballType.queuedUpgrades <= 2 then
                                table.insert(ballType.queuedUpgrades, statName)
                            end
                            print("Not enough money to upgrade " .. ballType.name .. "'s " .. statName)
                        end
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
                end
                
                local upgradeCount = 0
                for _, queuedUpgrade in ipairs(ballType.queuedUpgrades) do
                    if queuedUpgrade == statName then
                        upgradeCount = upgradeCount + 1
                    end
                end
                setFont(30)
                if upgradeCount > 0 then
                    love.graphics.setColor(161/255, 231/255, 1, 1)
                    love.graphics.print((statName == "cooldown" and "-" or "+") .. upgradeCount, x + cellWidth/3*2 - 5, y - 5) -- Display queued upgrade count\
                end
                intIndex = intIndex + 1
                love.graphics.setColor(1,1,1,1)
            end
        end
        suit.layout:row(statsWidth, 20) -- Add spacing for the separator
        x, y = suit.layout:nextRow()
        --if it isnt the last ballType, add a seperator
        y = y + 150 -- Add padding to the y position for the next row
    x = screenWidth - statsWidth + 10 + xOffset -- Reset x position for the next ball type, including xOffset
    end
    if not (tableLength(Balls.getUnlockedBallTypes()) >= 5) then
        x = x + 15 + xOffset
        suit.layout:reset(x, y, 10, 10)
        love.graphics.draw(uiSmallWindowImg, x-25,y) -- Draw the background window image
        x = x - 10
        y = y
        suit.layout:reset(x, y, 10, 10)
        -- Button to unlock a new ball type
        setFont(30)
        local angle = angle or math.rad(1.5) -- Default angle if not provided
        love.graphics.setColor(1, 1, 1, 1)
        setFont(35)
        local levelRequirement = Player.newWeaponLevelRequirement or 5
        suit.Button("unlock new weapon at lvl " .. levelRequirement, {align = "center", color = invisButtonColor}, suit.layout:row(uiSmallWindowImg:getWidth() - 25, uiSmallWindowImg:getHeight() - 27))
        if unlockNewWeaponQueued then
            Balls.NextBallPriceIncrease()
            setLevelUpShop(true) -- Set the level up shop with ball unlockedBallTypes
            Player.choosingUpgrade = true -- Set the flag to indicate leveling up
            unlockNewWeaponQueued = false
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

function drawLevelUpShop()
    -- Initialize layout for the buttons
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
        if isMouseOver then
            --love.graphics.setColor(48/255 * 0.9, 153/255 * 0.9, 186/255 * 0.9, opacity)
        else
            love.graphics.setColor(0.5, 0.5, 0.5, opacity) -- Brighter background
        end
        --love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight)
        love.graphics.draw(uiBigWindowImg, buttonX - 10 * buttonWidth/uiBigWindowImg:getWidth(), buttonY, 0, buttonWidth/uiBigWindowImg:getWidth(), buttonHeight/uiBigWindowImg:getHeight()) -- Draw the background window image
        -- Draw labels with opacity
        love.graphics.setColor(1,1,1,opacity)
        

        suit.layout:row(buttonWidth-20,15)
        -- type specific logic
        if levelUpShopType == "playerUpgrade" then
            love.graphics.setColor(1,1,1,opacity)
            setFont(35)
            dress:Label(currentUpgrade.name, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 50))
            love.graphics.setColor(1,1,1,1)
            setFont(24)
            dress:Label(currentUpgrade.description, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, buttonHeight - 100))
            -- draw the icon
            local icon = iconsImg[currentUpgrade.name]
            if icon then
                local iconX = buttonX + buttonWidth/2 - icon:getWidth()*2/2
                love.graphics.setColor(1,1,1,opacity)
                love.graphics.draw(icon, iconX, buttonY + buttonHeight - 150, 0, 2, 2)
            end
        else
            setFont(35)
            dress:Label(currentUpgrade.name, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 50))
            setFont(24)
            dress:Label(currentUpgrade.description, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 200))
            suit.layout:row(buttonWidth - 20, 15)
            for statName, statValue in pairs(Balls.getBallList()[currentUpgrade.name].stats) do
                love.graphics.setColor(1,1,1,opacity)
                setFont(24)
                dress:Label(statName .. ": " .. statValue, {align = "center", color = {normal = {fg = {1,1,1,opacity}}}}, suit.layout:row(buttonWidth - 30, 30))
            end
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
            Timer.after(15, function() 
                if Player.choosingUpgrade then Player.choosingUpgrade = false end
            end)
            Player.choosingUpgrade = false
            if not usingMoneySystem and Player.currentCore ~= "Farm Core" then
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
    if Player.rerolls > 0 then
        if suit.Button("Reroll", {id = buttonID, align = "center"}, suit.layout:row(w,h)).hit then
            Player.rerolls = Player.rerolls - 1
            local isBallShop = levelUpShopType == "ball"
            setLevelUpShop(isBallShop) -- Reroll the upgrades
        end
    end

end

function upgradesUI.draw()

    drawPlayerStats() -- Draw the player stats table
    drawPlayerUpgrades() -- Draw the player upgrades table
    drawBallStats() -- Draw the ball stats table
    drawInterestUpgrade()
    --drawPerkUpgrade() -- Draw the player perks table
    --drawPaddleUpgrades()

    -- Draw separator lines
    if usingMoneySystem then
        love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.max(math.min(math.max(0, 1-math.abs(Balls.getMinX()-statsWidth)/100), 1),math.min(math.max(0, 1-math.max(paddle.x-statsWidth,0)/100), 1))) -- Light gray
        love.graphics.rectangle("fill", statsWidth, 0, 1, screenHeight) -- Separator line
        love.graphics.setColor(0.6, 0.6, 0.6, 0.6*math.max(math.min(math.max(0, 1-math.abs(Balls.getMaxX()-(screenWidth - statsWidth))/100), 1), math.min(math.max(0, 1-math.max((screenWidth - statsWidth) - (paddle.x + paddle.width),0)/100))))
        love.graphics.rectangle("fill", screenWidth - statsWidth, 0, 1, screenHeight)
        love.graphics.setColor(0.6, 0.6, 0.6, 0.6* mapRangeClamped(math.abs(getHighestBrickY() + brickHeight - paddle.y), 0, 150, 1, 0)) -- Reset color to white
        love.graphics.rectangle("fill", statsWidth, paddle.y, screenWidth - statsWidth * 2, 1) -- Draw the paddle area
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white   
    end
    
    -- Draw Player.bricksDestroyed at the bottom left of the screen

    -- Draw stat hover label if hovering a stat
    if hoveredStatName then
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
    
end

return upgradesUI